defmodule Azalea.TreeTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Azalea, as: A

  describe "creating a new tree" do
    test ".new/0 assigns a value of `nil` and an empty list of children" do
      tree = A.Tree.new()
      assert is_nil(tree.value)
      assert Enum.empty?(tree.children)
    end

    test ".new/1 assigns the given parameter as the tree's value" do
      check all v <- StreamData.string(:printable) do
        tree = A.Tree.new(v)
        assert tree.value == v
      end
    end

    test ".new/2 wraps the given children into trees" do
      check all v <- StreamData.string(:printable),
                children <- StreamData.list_of(StreamData.string(:printable), max_length: 5)
      do
        tree = A.Tree.new(v, children)
        assert tree.value == v
        assert Enum.all?(tree.children, fn child -> child.__struct__ == A.Tree end)
        assert Enum.map(tree.children, fn %A.Tree{value: value} -> value end) == children
      end
    end
  end
end
