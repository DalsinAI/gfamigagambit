/* std::mutex for a C++ library built without threads (gthreads), forced in
 * ahead of every Gambit source (-include). Gambit guards its lazily built
 * payoff tables and tree layouts with std::mutex, and its GUI runs the Nash
 * solvers on a wxThread, so the lock has to be a real one: here it is the
 * AmigaOS pthread library's mutex, the one wxThread's own locks use.
 * With a library that has gthreads, <mutex> has its own and this adds
 * nothing. GBT_AMIGA_MUTEX_TEST builds it anyway (tests/test_mutex.cpp).
 * Copyright (c) 2026 AmiCradle Team. GPL-2 or later, like Gambit. */
#ifndef GBT_AMIGA_MUTEX_H
#define GBT_AMIGA_MUTEX_H

#ifdef __cplusplus
#include <mutex>

#if !defined( _GLIBCXX_HAS_GTHREADS ) || defined( GBT_AMIGA_MUTEX_TEST )
#include <pthread.h>

#ifdef GBT_AMIGA_MUTEX_TEST
namespace gbt_test {
#else
namespace std _GLIBCXX_VISIBILITY( default ) {
#endif

class mutex
{
    pthread_mutex_t m_m;

public:
    mutex() noexcept { pthread_mutex_init( &m_m, nullptr ); }
    ~mutex() { pthread_mutex_destroy( &m_m ); }
    mutex( const mutex & ) = delete;
    mutex &operator=( const mutex & ) = delete;
    void lock() { pthread_mutex_lock( &m_m ); }
    bool try_lock() noexcept { return pthread_mutex_trylock( &m_m ) == 0; }
    void unlock() { pthread_mutex_unlock( &m_m ); }
    pthread_mutex_t *native_handle() noexcept { return &m_m; }
};

}
#endif
#endif

#endif
