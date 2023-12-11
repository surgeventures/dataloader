defmodule Dataloader.Task do
  @moduledoc """
  This module is a wrapper around Task module to support tracing with Spandex.
  """

  @spec async((() -> any())) :: Task.t()
  def async(fun) do
    tracer = Application.get_env(:dataloader, :tracer)

    case tracer.current_context() do
      {:ok, context} ->
        Task.async(fn ->
          tracer.continue_trace("continue_trace", context)

          try do
            fun.()
          after
            tracer.finish_trace()
          end
        end)

      {:error, _message} ->
        Task.async(fun)
    end
  end

  @spec async_stream(Enumerable.t(), (term -> term), keyword) :: Enumerable.t()
  def async_stream(items, fun, opts) do
    tracer = Application.get_env(:dataloader, :tracer)

    tracer.start_span("hello_world")
    tracer.finish_span("bye_world")

    # raise inspect(tracer.current_context())

    case tracer.current_context() do
      {:ok, context} ->
        Task.async_stream(
          items,
          fn arg ->
            tracer.continue_trace("continue_trace", context)

            try do
              fun.(arg)
            after
              tracer.finish_trace()
            end
          end,
          opts
        )

      {:error, _message} ->
        Task.async_stream(items, fun, opts)
    end
  end
end
