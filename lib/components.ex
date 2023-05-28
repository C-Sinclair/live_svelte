defmodule LiveSvelte.Components.Builder do
  require Logger

  defmacro __before_compile__(env) do
    components = get_svelte_components()

    Enum.each(components, fn component ->
      Logger.info("Surfacing Svelte component: #{component}")
    end)

    quote do
      unquote(Enum.map(components, &name_to_function/1))
    end
  end

  def get_svelte_components do
    __DIR__
    |> escape_deps_directory()
    |> Path.join("./assets/svelte/**/*.svelte")
    |> Path.wildcard()
    |> Enum.filter(&(not String.contains?(&1, "_build/")))
    |> Enum.map(fn path ->
      path
      |> Path.basename()
      |> String.replace(".svelte", "")
    end)
  end

  def escape_deps_directory(dir) do
    parent = Path.expand("../", dir)

    cond do
      Path.basename(dir) in ["_build", "deps"] ->
        parent

      dir == "/" ->
        raise "Hit root directory. This is an issue!"

      true ->
        escape_deps_directory(parent)
    end
  end

  def name_to_function(name) do
    quote do
      def unquote(:"#{name}")(assigns) do
        props =
          assigns
          |> Map.filter(fn
            {:svelte_opts, _v} -> false
            {k, _v} -> k not in [:__changed__]
            _ -> false
          end)

        var!(assigns) =
          assign(assigns,
            __component_name: unquote(name),
            props: props || %{}
          )

        ~H"""
        <LiveSvelte.svelte
          name={Map.get(var!(assigns), :__component_name)}
          class={Map.get(var!(assigns), :class)}
          ssr={LiveSvelte.get_ssr(var!(assigns)) |> IO.inspect(label: "ssr")}
          props={Map.get(var!(assigns), :props, %{})}
        />
        """
      end
    end
  end
end

defmodule LiveSvelte.Components do
  @moduledoc """
  Macros to improve the developer experience of crossing the Liveview/Svelte boundary.
  """
  @before_compile LiveSvelte.Components.Builder

  @doc """
  Generates functions local to your current module that can be used to render Svelte components.
  """
  defmacro __using__(_opts) do
    IO.puts("calling using!")

    quote do
      import __MODULE__
    end
  end
end
