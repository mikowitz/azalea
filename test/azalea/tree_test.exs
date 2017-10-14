defmodule Azalea.TreeTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import Azalea.Test.TreeGenerators

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

  test "is_child?/2 checks whether a tree is a child of another tree" do
    check all tree <- gen_tree(),
              other_child <- gen_tree()
    do
      Enum.each(tree.children, fn child ->
        assert A.Tree.is_child?(child, tree)
      end)
      refute A.Tree.is_child?(other_child, tree)
    end
  end

  test "add_child/2 adds `child` as `tree`'s first child" do
    check all tree <- gen_tree(),
              child <- gen_tree()
    do
      tree = A.Tree.add_child(tree, child)
      assert Enum.at(tree.children, 0) == child
    end
  end

  test "insert_child/3 adds `child` to `tree` at `index`" do
    check all tree <- gen_tree(),
              child <- gen_tree(),
              index <- StreamData.integer(0..length(tree.children)-1)
    do
      tree = A.Tree.insert_child(tree, child, index)
      assert child == Enum.at(tree.children, index)
    end
  end

  test "pop_child/1 removes the tree's first child" do
    check all tree <- gen_tree(),
              tree.children != []
    do
      original_children = tree.children
      {child, tree} = A.Tree.pop_child(tree)
      refute A.Tree.is_child?(child, tree)
      assert child == Enum.at(original_children, 0)
    end
  end

  test "remove_child/2 removes the child at the given index" do
    check all tree <- gen_tree(),
              tree.children != [],
              index <- StreamData.integer(0..length(tree.children)-1)
    do
      original_children = tree.children
      {child, tree} = A.Tree.remove_child(tree, index)
      refute A.Tree.is_child?(child, tree)
      assert child == Enum.at(original_children, index)
    end
  end

  describe "Enumerable" do
    setup do
      tree = A.Tree.new(:a, [
        :b,
        A.Tree.new(:c, [
          :d,
          A.Tree.new(:e, [:f])
        ]),
        A.Tree.new(:g, [
          A.Tree.new(:h)
        ])
      ])
      {:ok, %{tree: tree}}
    end

    test "Enum.count/1 returns the full size of the tree", context do
      assert A.Tree.length(context.tree) == 8
    end

    test "Enum.member?/2 returns whether the child is in the tree's children" do
      check all tree <- gen_tree(),
                other_child <- gen_tree()
      do
        Enum.each(tree.children, fn child ->
          assert A.Tree.is_child?(child, tree)
        end)
        refute A.Tree.is_child?(other_child, tree)
      end
    end

    test "Enum.reduce/3 reduces the tree to a single value", context do
      reducer = fn tree, acc -> acc ++ [tree.value] end
      assert A.Tree.reduce(context.tree, [], reducer) == ~w(a b c d e f g h)a

      mapper = fn tree -> %{tree | value: to_string(tree.value)} end
      assert A.Tree.reduce(A.Tree.map(context.tree, mapper), [], reducer) == ~w(a b c d e f g h)
    end
  end
end
