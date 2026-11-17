// Host test for compat/gbt_amiga_mutex.h: the pthread-backed mutex (built
// under its own namespace here, since the host's <mutex> has one) keeps two
// threads from losing counts, and works with std::lock_guard and
// std::unique_lock, which Gambit uses with it.
// Copyright (c) 2026 AmiCradle Team. GPL-2 or later, like Gambit.
#define GBT_AMIGA_MUTEX_TEST
#include "gbt_amiga_mutex.h"
#include <cstdio>
#include <pthread.h>

static gbt_test::mutex m;
static long count = 0;

static void *work( void * )
{
    for( int i = 0; i < 200000; i++ )
    {
        std::lock_guard<gbt_test::mutex> g( m );
        count++;
    }
    return nullptr;
}

int main()
{
    int fails = 0;
    pthread_t a, b;
    pthread_create( &a, nullptr, work, nullptr );
    pthread_create( &b, nullptr, work, nullptr );
    pthread_join( a, nullptr );
    pthread_join( b, nullptr );
    if( count != 400000 ) { std::printf( "FAIL: count %ld\n", count ); fails++; }

    m.lock();
    if( m.try_lock() ) { std::printf( "FAIL: try_lock on a held mutex\n" ); fails++; }
    m.unlock();
    if( !m.try_lock() ) { std::printf( "FAIL: try_lock on a free mutex\n" ); fails++; }
    m.unlock();
    {
        std::unique_lock<gbt_test::mutex> u( m );
        if( !u.owns_lock() ) { std::printf( "FAIL: unique_lock\n" ); fails++; }
    }
    if( !m.try_lock() ) { std::printf( "FAIL: unique_lock did not unlock\n" ); fails++; }
    m.unlock();
    if( !fails )
        std::printf( "mutex: all checks passed\n" );
    return fails != 0;
}
