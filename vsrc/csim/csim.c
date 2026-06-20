/**
 * @file csim.c
 * @brief MESI 多核 Cache 模拟器
 * @author daiyiyang <24300240114@m.fudan.edu.cn>
 */

#include <stdio.h>
#include <getopt.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>

/* ===== 全局参数 ===== */
int s = 0, S = 0, E = 0, b = 0;          // 缓存配置：组索引位数、组数、关联度、块偏移位数
int num_cores = 0;                       // 核心数
char trace_file[256] = "test.trace";     // 默认 trace 文件
int counter = 0;                         // LRU 全局时间戳

/* ===== MESI 状态 ===== */
typedef enum {
    MESI_I = 0,   // 无效
    MESI_S,       // 共享
    MESI_E,       // 独占且干净
    MESI_M        // 已修改
} MESIState;

/* ===== 缓存行结构 ===== */
typedef struct {
    int tag;          // 标记
    int time;         // LRU 时间戳
    MESIState state;  // MESI 状态
} CacheLine;

typedef CacheLine* CacheSet;   // 一组
typedef CacheSet* Cache;       // 一个核心的全部缓存组

Cache *caches = NULL;         // caches[core_id][set_index][way]

/* ===== 函数声明 ===== */
void mallocCaches(void);
void freeCaches(void);
int findReplaceWay(int core, int setIndex, int timestamp, unsigned long *replaced_addr);
void processRequest(int core, int timestamp, char type, unsigned long addr, int size);
void readTraceFile(void);

/* ===== 分配所有核心的缓存 ===== */
void mallocCaches(void) {
    caches = (Cache *)malloc(num_cores * sizeof(Cache));
    assert(caches);
    for (int c = 0; c < num_cores; c++) {
        caches[c] = (CacheSet *)malloc(S * sizeof(CacheSet));
        assert(caches[c]);
        for (int i = 0; i < S; i++) {
            caches[c][i] = (CacheLine *)malloc(E * sizeof(CacheLine));
            assert(caches[c][i]);
            for (int w = 0; w < E; w++) {
                caches[c][i][w].state = MESI_I;
                caches[c][i][w].time  = 0;
                caches[c][i][w].tag   = 0;
            }
        }
    }
}

/* ===== 释放缓存 ===== */
void freeCaches(void) {
    if (!caches) return;
    for (int c = 0; c < num_cores; c++) {
        if (caches[c]) {
            for (int i = 0; i < S; i++) {
                if (caches[c][i]) {
                    free(caches[c][i]);
                }
            }
            free(caches[c]);
        }
    }
    free(caches);
    caches = NULL;
}

/* ===== 查找替换行（若无无效行则执行 LRU 替换，并输出 Replace / BusWb） =====
 * 返回被选中的 way，并将该行状态置为 I（如果原为 M 则输出 BusWb）
 * replaced_addr 输出被替换块的物理地址（用于日志）
 */
int findReplaceWay(int core, int setIndex, int timestamp, unsigned long *replaced_addr) {
    CacheSet set = caches[core][setIndex];

    // 优先找无效行
    for (int w = 0; w < E; w++) {
        if (set[w].state == MESI_I) {
            *replaced_addr = 0;   // 无替换
            return w;
        }
    }

    // 无无效行，使用 LRU 替换
    int min_time = 0x7fffffff;
    int way = 0;
    for (int w = 0; w < E; w++) {
        if (set[w].time < min_time) {
            min_time = set[w].time;
            way = w;
        }
    }

    // 计算被替换块的地址
    unsigned long replaced = ((unsigned long)set[way].tag << (s + b)) |
                             ((unsigned long)setIndex << b);
    *replaced_addr = replaced;

    // 输出 Replace 动作（核动作）
    printf("%d %d 0x%lx Replace\n", timestamp, core, replaced);

    // 如果被替换行是 M，需要写回
    if (set[way].state == MESI_M) {
        printf("%d bus 0x%lx BusWb\n", timestamp, replaced);
    }

    // 置为 I，准备覆盖
    set[way].state = MESI_I;
    return way;
}

/* ===== 处理单条内存请求 ===== */
void processRequest(int core, int timestamp, char type, unsigned long addr, int size) {
    // 忽略 size（仅用于展示）
    unsigned long setIndex = (addr >> b) & ((1ULL << s) - 1);
    unsigned long tag = addr >> (s + b);
    CacheSet set = caches[core][setIndex];

    // 先输出核的读/写动作
    if (type == 'R')
        printf("%d %d 0x%lx PrRd\n", timestamp, core, addr);
    else  // 'W'
        printf("%d %d 0x%lx PrWr\n", timestamp, core, addr);

    // ---------- 查找命中 ----------
    int hit_way = -1;
    for (int w = 0; w < E; w++) {
        if (set[w].state != MESI_I && set[w].tag == (int)tag) {
            hit_way = w;
            break;
        }
    }

    if (hit_way != -1) {
        // ---------- 命中 ----------
        CacheLine *line = &set[hit_way];

        if (type == 'R') {
            // 读命中：直接更新 LRU，状态不变
            line->time = ++counter;
            return;
        } else { // 'W'
            if (line->state == MESI_M || line->state == MESI_E) {
                // 独占写：不需总线，直接变为 M
                line->state = MESI_M;
                line->time = ++counter;
            } else if (line->state == MESI_S) {
                // 共享写：需要 Flush 使其他副本无效
                printf("%d bus 0x%lx Flush\n", timestamp, addr);

                // 遍历所有其他核，使该块无效
                for (int c = 0; c < num_cores; c++) {
                    if (c == core) continue;
                    CacheSet other_set = caches[c][setIndex];
                    for (int w = 0; w < E; w++) {
                        if (other_set[w].state != MESI_I && other_set[w].tag == (int)tag) {
                            // 如果其他核是 M，需写回
                            if (other_set[w].state == MESI_M) {
                                unsigned long replaced_addr = ((unsigned long)other_set[w].tag << (s + b)) |
                                                              ((unsigned long)setIndex << b);
                                printf("%d bus 0x%lx BusWb\n", timestamp, replaced_addr);
                            }
                            other_set[w].state = MESI_I;
                        }
                    }
                }
                // 自己变为 M
                line->state = MESI_M;
                line->time = ++counter;
            }
        }
        return;
    }

    // ---------- 未命中 ----------
    // 先处理总线事务，再分配行（可能涉及替换）

    if (type == 'R') {
        // ----- 读未命中：BusRd -----
        printf("%d bus 0x%lx BusRd\n", timestamp, addr);

        int has_copy = 0;   // 是否有其他核持有该块
        int has_m = 0;      // 是否有其他核处于 M 状态（最多一个）

        // 遍历其他核，处理响应
        for (int c = 0; c < num_cores; c++) {
            if (c == core) continue;
            CacheSet other_set = caches[c][setIndex];
            for (int w = 0; w < E; w++) {
                if (other_set[w].state != MESI_I && other_set[w].tag == (int)tag) {
                    has_copy = 1;
                    if (other_set[w].state == MESI_M) {
                        has_m = 1;
                        // M 需要写回并变为 S
                        unsigned long replaced_addr = ((unsigned long)other_set[w].tag << (s + b)) |
                                                      ((unsigned long)setIndex << b);
                        printf("%d bus 0x%lx BusWb\n", timestamp, replaced_addr);
                        other_set[w].state = MESI_S;
                    } else if (other_set[w].state == MESI_E) {
                        // E 变为 S
                        other_set[w].state = MESI_S;
                    }
                    // S 保持不变
                }
            }
        }

        // 决定本核新状态：若有其他核持有则 S，否则 E
        MESIState new_state = has_copy ? MESI_S : MESI_E;

        // 分配行（可能替换）
        unsigned long replaced_addr;
        int way = findReplaceWay(core, setIndex, timestamp, &replaced_addr);
        CacheLine *line = &set[way];
        line->tag = (int)tag;
        line->state = new_state;
        line->time = ++counter;

    } else { // 'W'
        // ----- 写未命中：BusRdX -----
        printf("%d bus 0x%lx BusRdX\n", timestamp, addr);

        // 使其他核该块无效（同时处理可能的 M 写回）
        for (int c = 0; c < num_cores; c++) {
            if (c == core) continue;
            CacheSet other_set = caches[c][setIndex];
            for (int w = 0; w < E; w++) {
                if (other_set[w].state != MESI_I && other_set[w].tag == (int)tag) {
                    if (other_set[w].state == MESI_M) {
                        unsigned long replaced_addr = ((unsigned long)other_set[w].tag << (s + b)) |
                                                      ((unsigned long)setIndex << b);
                        printf("%d bus 0x%lx BusWb\n", timestamp, replaced_addr);
                    }
                    other_set[w].state = MESI_I;
                }
            }
        }

        // 分配行，状态为 M
        unsigned long replaced_addr;
        int way = findReplaceWay(core, setIndex, timestamp, &replaced_addr);
        CacheLine *line = &set[way];
        line->tag = (int)tag;
        line->state = MESI_M;
        line->time = ++counter;
    }
}

/* ===== 读取 trace 文件 ===== */
void readTraceFile(void) {
    FILE *fp = fopen(trace_file, "r");
    if (!fp) {
        fprintf(stderr, "Error: cannot open trace file '%s'\n", trace_file);
        exit(1);
    }

    char line[256];
    int line_num = 0;
    while (fgets(line, sizeof(line), fp)) {
        line_num++;
        // 跳过空行和注释行
        if (line[0] == '\n' || line[0] == '/' || line[0] == '#')
            continue;

        int timestamp, core, size;
        char type;
        unsigned long addr;
        // 解析格式: timestamp core_id type addr size
        int n = sscanf(line, "%d %d %c %lx %d", &timestamp, &core, &type, &addr, &size);
        if (n != 5) {
            // 若格式不匹配，跳过（可能是空行或其他格式）
            continue;
        }
        // 检查 core_id 合法性
        if (core < 0 || core >= num_cores) {
            fprintf(stderr, "Warning: invalid core id %d at line %d\n", core, line_num);
            continue;
        }
        processRequest(core, timestamp, type, addr, size);
    }
    fclose(fp);
}

/* ===== 主函数 ===== */
int main(int argc, char *argv[]) {
    int opt;
    while ((opt = getopt(argc, argv, "s:E:b:t:n:")) != -1) {
        switch (opt) {
            case 's':
                s = atoi(optarg);
                if (s > 0) S = 1 << s;
                break;
            case 'E':
                E = atoi(optarg);
                break;
            case 'b':
                b = atoi(optarg);
                break;
            case 'n':
                num_cores = atoi(optarg);
                break;
            case 't':
                strcpy(trace_file, optarg);
                break;
            default:
                fprintf(stderr, "Usage: %s -s <s> -E <E> -b <b> -n <cores> [-t <tracefile>]\n", argv[0]);
                return 1;
        }
    }

    // 参数验证
    if (s <= 0 || E <= 0 || b <= 0 || num_cores <= 0) {
        fprintf(stderr, "Error: -s, -E, -b, -n must be positive integers.\n");
        fprintf(stderr, "Usage: %s -s <s> -E <E> -b <b> -n <cores> [-t <tracefile>]\n", argv[0]);
        return 1;
    }
    if (s + b > 31) {
        fprintf(stderr, "Error: s + b too large (max 31).\n");
        return 1;
    }

    // 分配缓存
    mallocCaches();

    // 处理 trace
    readTraceFile();

    // 清理
    freeCaches();

    return 0;
}
