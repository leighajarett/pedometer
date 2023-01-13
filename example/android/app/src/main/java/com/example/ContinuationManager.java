package com.example;


import org.thavam.util.concurrent.blockingMap.BlockingHashMap;
import org.thavam.util.concurrent.blockingMap.BlockingMap;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import io.flutter.plugin.common.MethodChannel;

public class ContinuationManager {
    static {
        System.loadLibrary("health_connect");
    }

    public static BlockingMap<String, Object> awaitingContinuations = new BlockingHashMap<>();
    private static final ExecutorService executor = Executors.newCachedThreadPool();


    public static void putObject(String tag, Object o) {
        executor.submit(() -> {
            try {
                ContinuationManager.awaitingContinuations.offer(tag, o, 10, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
    }

    public static void getGlobalRefFromTag(String tag, MethodChannel.Result result) {
        executor.submit(() -> {
            try {
                Object o = awaitingContinuations.take(tag, 10, TimeUnit.SECONDS);
                result.success(getGlobalRef(o));
            } catch (InterruptedException e) {
                e.printStackTrace();
                result.error("oops", "oops", "oopsy doopsy!");
            }

        });
    }

    native static long getGlobalRef(Object o);
}
