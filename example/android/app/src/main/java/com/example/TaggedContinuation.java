package com.example;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlinx.coroutines.Dispatchers;

@Keep
public class TaggedContinuation implements Continuation {
  private String tag;

  public TaggedContinuation(String tag) {
    this.tag = tag;
  }

  @NonNull
  @Override
  public CoroutineContext getContext() {
    return (CoroutineContext) Dispatchers.getIO();
  }

  @Override
  public void resumeWith(Object o) {
    ContinuationManager.putObject(tag, o);
  }
}
