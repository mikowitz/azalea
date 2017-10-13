defmodule Azalea.Tree do
  @type t :: %Azalea.Tree{value: any(), children: [Azalea.Tree.t]}

  defstruct [:value, :children, :id]

  @spec new :: Azalea.Tree.t
  @spec new(any()) :: Azalea.Tree.t
  @spec new(any(), [any()]) :: Azalea.Tree.t
  def new, do: new(nil)
  def new(value), do: new(value, [])
  def new(value, children) do
    %__MODULE__{value: value, children: wrap_children(children), id: make_ref()}
  end

  defp wrap_children(children) when is_list(children) do
    Enum.map(children, &wrap_child/1)
  end

  defp wrap_child(tree = %__MODULE__{}), do: tree
  defp wrap_child(child), do: new(child)
end
