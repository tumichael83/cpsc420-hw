/* Author: Andrew S. Waterman, Yunsup Lee
 *         Parallel Computing Laboratory
 *         Electrical Engineering and Computer Sciences
 *         University of California, Berkeley
 *
 * Copyright (c) 2008, The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the University of California, Berkeley nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS ''AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE REGENTS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#ifndef __HOST_H
#define __HOST_H

#include <stdint.h>
#include <stdio.h>
extern int debug_level;
extern bool vptrace;

#undef HTONS
#undef HTONL
#undef HTONLL
#undef NTOHS
#undef NTOHL
#undef NTOHLL

#undef LITTLE_ENDIAN
#undef BIG_ENDIAN

#if defined(__x86_64__) || defined(__i386__)

  #define LITTLE_ENDIAN

  #ifdef TARGET_BIG_ENDIAN

  static inline uint16_t HTONS(uint16_t x)
  {
    asm("xchgb %%al,%%ah" : "=a" (x) : "a" (x));
    return x;
  }

  static inline uint32_t HTONL(uint32_t x)
  {
    asm("bswapl %%eax" : "=a" (x) : "a" (x));
    return x;
  }

  static inline uint64_t HTONLL(uint64_t x)
  {
    asm("bswapq %%rax" : "=a" (x) : "a" (x));
    return x;
  }

  #else

  #define HTONS(x) (x)
  #define HTONL(x) (x)
  #define HTONLL(x) (x)

  #endif

  #define NTOHS HTONS
  #define NTOHL HTONL
  #define NTOHLL HTONLL

  static inline void lock(int* ptr)
  {
    int reg;
    do
    {
      reg = 1;
      __asm__ __volatile__ ("xchg %0, (%2)" : "=a"(reg) : "0"(reg),"b"(ptr) : "memory");
    } while(reg == 1);
  }

  #define HAS_FETCH_ADD  
  static inline int fetch_add(int* ptr, int value)
  {
    __asm__ __volatile__ ("lock xadd %0, (%2)" : "=a"(value) : "0"(value),"b"(ptr) : "memory");
    return value;
  }

  static inline void unlock(int* ptr)
  {
    *ptr = 0;
  }

#else

  #error Host machine is unknown!

#endif

#endif // __HOST_H
