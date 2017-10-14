defmodule Azalea.Test.TreeGenerators do
  alias Azalea, as: A

  def gen_empty_tree do
    StreamData.map(StreamData.string(:printable), &A.Tree.new/1)
  end

  def gen_tree, do: StreamData.map(StreamData.integer(1..5), &gen_tree/1)
  def gen_tree(depth) do
    gen_tree(
      depth,
      Enum.at(gen_empty_tree(), 0)
    )
  end
  def gen_tree(0, tree), do: tree
  def gen_tree(n, tree) do
    child_count = :rand.uniform(n)
    children = Enum.take(gen_empty_tree(), child_count) |> Enum.map(&gen_tree(n-1, &1))
    %{tree | children: children}
  end
end
