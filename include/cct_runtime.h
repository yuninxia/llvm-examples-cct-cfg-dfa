#pragma once
#ifdef __cplusplus
extern "C" {
#endif
void __cct_enter(const char *fn);
void __cct_exit(const char *fn);
#ifdef __cplusplus
}
#endif
