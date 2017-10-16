defmodule Azalea.ZipperTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import Azalea.Test.TreeGenerators

  alias Azalea, as: A

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
    reducer = fn tree, acc -> acc ++ [tree.value] end
    {:ok, %{tree: tree, reducer: reducer}}
  end

  test "from_tree/1 generates a zipper from the given tree" do
    check all tree <- gen_tree() do
      zipper = A.Zipper.from_tree(tree)
      assert zipper.focus == tree
      assert zipper.crumbs == []
    end  
  end

  test "down/1 moves to the first (leftmost) childnode", context do
    zipper = A.Zipper.from_tree(context.tree)
    zipper = A.Zipper.down(zipper)
    assert zipper.focus.value == :b
    assert length(zipper.crumbs) == 1
    crumb = Enum.at(zipper.crumbs, 0)
    assert crumb.parent == context.tree
    assert crumb.left == []
    assert Enum.map(crumb.right, &(&1.value)) == [:c, :g]
  end

  test "down/1 returns an error tuple when there is no further child", context do
    zipper = A.Zipper.from_tree(context.tree)
    zipper = A.Zipper.down(zipper)
    error = A.Zipper.down(zipper)
    assert error == {:error, :no_children}
  end

  test "right/1 return the next sibling node to the right", context do
    zipper = A.Zipper.from_tree(context.tree)
    zipper = zipper |> A.Zipper.down |> A.Zipper.right

    assert zipper.focus.value == :c
    assert length(zipper.crumbs) == 2
    crumb = Enum.at(zipper.crumbs, 0)
    assert crumb.parent == context.tree
    assert Enum.map(crumb.left, &(&1.value)) == [:b]
    assert Enum.map(crumb.right, &(&1.value)) == [:g]
  end

  test "right/1 returns an error when there is no further sibling", context do
    zipper = A.Zipper.from_tree(context.tree)
    error = zipper |> A.Zipper.down |> A.Zipper.right 
            |> A.Zipper.right |> A.Zipper.right
    assert error == {:error, :no_right_sibling}
  end

  test "up/1 moves up to the current focus' parent", context do
    zipper = A.Zipper.from_tree(context.tree)
    zipper = zipper |> A.Zipper.down |> A.Zipper.right |> A.Zipper.up

    assert zipper.focus.value == :a
    assert zipper.crumbs == []
    
    zipper = zipper |> A.Zipper.down |> A.Zipper.right |> A.Zipper.down |> A.Zipper.right |> A.Zipper.up

    assert zipper.focus.value == :c
    assert length(zipper.crumbs) == 2
    crumb = Enum.at(zipper.crumbs, 0)
    assert crumb.parent == context.tree
    assert Enum.map(crumb.left, &(&1.value)) == [:b]
    assert Enum.map(crumb.right, &(&1.value)) == [:g]
  end

  test "up/1 returns an error when there is no parent", context do
    zipper = A.Zipper.from_tree(context.tree)
    assert A.Zipper.up(zipper) == {:error, :no_parent}
  end

  test "left/1 moves to the next left sibling", context do
    zipper = context.tree |> A.Zipper.from_tree |> A.Zipper.down
             |> A.Zipper.right |> A.Zipper.left
    assert zipper.focus.value == :b
    assert length(zipper.crumbs) == 2
    crumb = Enum.at(zipper.crumbs, 0)
    assert crumb.parent == context.tree
    assert crumb.left == []
    assert Enum.map(crumb.right, &(&1.value)) == [:c, :g]
  end

  test "left/1 returns an error if there is no previous sibling", context do
    zipper = context.tree |> A.Zipper.from_tree |> A.Zipper.down
    assert A.Zipper.left(zipper) == {:error, :no_left_sibling}
  end
end
