defmodule Azalea.Tree do
  alias __MODULE__

  @type t :: %Azalea.Tree{value: any(), children: [Azalea.Tree.t]}

  defstruct [:value, :children, :id]

  def new, do: new(nil)
  def new(value), do: new(value, [])
  def new(value, children) do
    %__MODULE__{value: value, children: wrap_children(children), id: make_ref()}
  end

  defp wrap_children(children) when is_list(children) do
    Enum.map(children, &map_child/1)
  end

  defp map_child(tree = %__MODULE__{}), do: tree
  defp map_child(child), do: new(child)
end
