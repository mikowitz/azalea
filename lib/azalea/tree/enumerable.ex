defimpl Enumerable, for: Azalea.Tree do
  def count(tree), do: {:ok, _do_count(tree)}
  defp _do_count(%Azalea.Tree{children: []}), do: 1
  defp _do_count(tree) do
    1 + Enum.sum(Enum.map(tree.children, &_do_count/1))
  end

  def member?(tree, child) do
    {:ok, _is_member?(tree.children, child)}
  end
  defp _is_member?([], _), do: false
  defp _is_member?([c|_], c), do: true
  defp _is_member?([_|t], c), do: _is_member?(t, c)

  def reduce(tree, {:cont, acc}, fun) do
    Enum.reduce(tree.children, fun.(tree, acc), &reduce(&1, &2, fun))
  end
end
