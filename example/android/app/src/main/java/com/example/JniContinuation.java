package com.example;

import androidx.annotation.Keep;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlinx.coroutines.Dispatchers;

@Keep
public class JniContinuation<T> implements Continuation<T> {
  static {
    System.loadLibrary("health_connect");
  }
  private long functionPointer;

  public JniContinuation(long functionPointer) {
    this.functionPointer = functionPointer;
  }

  @Override
  public CoroutineContext getContext() {
    return (CoroutineContext) Dispatchers.getMain();
  }

  @Override
  public void resumeWith(Object o) {
    _resumeWith(functionPointer, (T)o);
  }

  private native void _resumeWith(long functionPointer, T result);
}
