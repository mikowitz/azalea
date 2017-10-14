defmodule Azalea.Tree do
  @type t :: %Azalea.Tree{value: any, children: [Azalea.Tree.t]}

  defstruct [:value, :children, :id]

  @spec new :: Azalea.Tree.t
  @spec new(any) :: Azalea.Tree.t
  @spec new(any, [any]) :: Azalea.Tree.t
  def new, do: new(nil)
  def new(value), do: new(value, [])
  def new(value, children) do
    %__MODULE__{value: value, children: wrap_children(children), id: make_ref()}
  end

  @spec is_child?(Azalea.Tree.t, Azalea.Tree.t) :: boolean
  def is_child?(child, tree) do
    Enum.member?(tree, child)
  end

  @spec add_child(Azalea.Tree.t, any) :: Azalea.Tree.t
  def add_child(tree = %Azalea.Tree{}, child) do
    with child <- wrap_child(child) do
      %{tree | children: [child|tree.children]}
    end
  end

  @spec insert_child(Azalea.Tree.t, any, integer) :: Azalea.Tree.t
  def insert_child(tree, child, index) do
    with child <- wrap_child(child) do
      %{tree | children: List.insert_at(tree.children, index, child)}
    end
  end

  @spec pop_child(Azalea.Tree.t) :: {Azalea.Tree.t, Azalea.Tree.t}
  def pop_child(tree = %Azalea.Tree{}) do
    {child, children} = List.pop_at(tree.children, 0)
    {child, %{tree | children: children}}
  end

  @spec remove_child(Azalea.Tree.t, integer) :: {Azalea.Tree.t, Azalea.Tree.t}
  def remove_child(tree = %Azalea.Tree{}, index) do
    {child, children} = List.pop_at(tree.children, index)
    {child, %{tree | children: children}}
  end

  @spec map(Azalea.Tree.t, fun) :: Azalea.Tree.t
  def map(tree, fun) do
    %{fun.(tree) | children: Enum.map(tree.children, &map(&1, fun))}
  end

  @spec length(Azalea.Tree.t) :: integer
  def length(tree), do: Enum.count(tree)

  @spec reduce(Azalea.Tree.t, term, (term, term -> term)) :: term
  def reduce(tree, acc, fun), do: Enum.reduce(tree, acc, fun)

  defp wrap_children(children) when is_list(children) do
    Enum.map(children, &wrap_child/1)
  end
  defp wrap_child(tree = %__MODULE__{}), do: tree
  defp wrap_child(child), do: new(child)

  @behaviour Access

  def fetch(tree = %Azalea.Tree{children: children}, index) when is_integer(index) do
    case Enum.at(children, index) do
      nil -> :error
      child -> {:ok, child}
    end
  end

  def get(tree, index, default \\ nil) when is_integer(index) do
    case fetch(tree, index) do
      {:ok, child} -> child
      :error -> default
    end
  end

  def get_and_update(tree, index, fun) do
    value = get(tree, index)

    case fun.(value) do
      {get, update} ->
        {get, %{tree | children: List.replace_at(tree.children, index, update)}}
      :pop ->
        {value, %{tree | children: List.delete_at(tree.children, index)}}
      x -> raise "#{inspect x}"
    end
  end

  def pop(tree, index) do
    case get(tree, index) do
      nil -> {nil, tree}
      child -> {child, %{tree | children: List.delete_at(tree.children, index)}}
    end
  end
end
