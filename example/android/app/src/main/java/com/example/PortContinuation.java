package com.example;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlinx.coroutines.Dispatchers;

@Keep
public class PortContinuation implements Continuation {
  static {
    System.loadLibrary("health_connect");
  }

  private long port;

  public PortContinuation(long port) {
    this.port = port;
  }

  @NonNull
  @Override
  public CoroutineContext getContext() {
    return (CoroutineContext) Dispatchers.getIO();
  }

  @Override
  public void resumeWith(Object o) {
    _resumeWith(port, o);
  }

  private native void _resumeWith(long port, Object result);
}
