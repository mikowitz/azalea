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
    zipper = A.Zipper.from_tree(tree)
    {:ok, %{tree: tree, zipper: zipper}}
  end

  test "from_tree/1 generates a zipper from the given tree" do
    check all tree <- gen_tree() do
      zipper = A.Zipper.from_tree(tree)
      assert zipper.focus == tree
      assert zipper.crumbs == []
    end  
  end

  test "down/1 moves to the first (leftmost) childnode", context do
    zipper = A.Zipper.down(context.zipper)
    assert zipper.focus.value == :b
    assert length(zipper.crumbs) == 1
    crumb = Enum.at(zipper.crumbs, 0)
    assert crumb.parent == context.tree
    assert crumb.left == []
    assert Enum.map(crumb.right, &(&1.value)) == [:c, :g]
  end

  test "down/1 returns an error tuple when there is no further child", context do
    zipper = A.Zipper.down(context.zipper)
    error = A.Zipper.down(zipper)
    assert error == {:error, :no_children}
  end

  test "right/1 return the next sibling node to the right", context do
    zipper = context.zipper |> A.Zipper.down |> A.Zipper.right

    assert zipper.focus.value == :c
    assert length(zipper.crumbs) == 2
    crumb = Enum.at(zipper.crumbs, 0)
    assert crumb.parent == context.tree
    assert Enum.map(crumb.left, &(&1.value)) == [:b]
    assert Enum.map(crumb.right, &(&1.value)) == [:g]
  end

  test "right/1 returns an error when there is no further sibling", context do
    error = context.zipper |> A.Zipper.down |> A.Zipper.right 
            |> A.Zipper.right |> A.Zipper.right
    assert error == {:error, :no_right_sibling}
  end

  test "up/1 moves up to the current focus' parent", context do
    zipper = context.zipper |> A.Zipper.down |> A.Zipper.right |> A.Zipper.up

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
    assert A.Zipper.up(context.zipper) == {:error, :no_parent}
  end

  test "left/1 moves to the next left sibling", context do
    zipper = context.zipper |> A.Zipper.down
             |> A.Zipper.right |> A.Zipper.left
    assert zipper.focus.value == :b
    assert length(zipper.crumbs) == 2
    crumb = Enum.at(zipper.crumbs, 0)
    assert crumb.parent == context.tree
    assert crumb.left == []
    assert Enum.map(crumb.right, &(&1.value)) == [:c, :g]
  end

  test "left/1 returns an error if there is no previous sibling", context do
    assert A.Zipper.left(context.zipper) == {:error, :no_left_sibling}
  end

  test "is_root?/1 returns true if the current focus has no parent", context do
    assert A.Zipper.is_root?(context.zipper)
  end

  test "is_root?/1 returns false for the current focus has a parent", context do
    refute context.zipper |> A.Zipper.down |> A.Zipper.is_root?
  end

  test "to_root/1 walks all the way back up the zipper and returns the root", context do
    assert A.Zipper.to_root(context.zipper) == context.zipper
    assert context.zipper |> A.Zipper.down |> A.Zipper.right |> A.Zipper.down |> A.Zipper.to_root == context.zipper
  end

  test "is_end?/1 returns true iff the focus is the end of a depth-first walk of the tree", context do
    refute A.Zipper.is_end?(context.zipper)
    refute context.zipper |> A.Zipper.down |> A.Zipper.is_end?
    refute context.zipper |> A.Zipper.down |> A.Zipper.right |> A.Zipper.is_end?
    refute context.zipper |> A.Zipper.down |> A.Zipper.right |> A.Zipper.right |> A.Zipper.is_end?
    assert context.zipper |> A.Zipper.down |> A.Zipper.right |> A.Zipper.right |> A.Zipper.down |> A.Zipper.is_end?
  end

  test "rightmost/1 moves to the rightmost sibling, or stays there", context do
    zipper = context.zipper |> A.Zipper.down |> A.Zipper.rightmost
    assert zipper.focus.value == :g

    assert A.Zipper.rightmost(zipper).focus.value == :g
  end

  test "leftmost/1 moves to the leftmost sibling, or stays there", context do
    zipper = context.zipper |> A.Zipper.down |> A.Zipper.leftmost
    assert zipper.focus.value == :b

    zipper = A.Zipper.rightmost(zipper)

    assert zipper.focus.value == :g
    assert A.Zipper.leftmost(zipper).focus.value == :b
    assert zipper |> A.Zipper.leftmost |> A.Zipper.rightmost |> (fn z -> z.focus.value end).() == :g
  end

  test "append_child/2 adds the item as the righttmost child of the current focus, without moving", context do
    zipper = A.Zipper.append_child(context.zipper, A.Tree.new(:i))
    assert length(zipper.focus.children) == 4
    assert zipper.focus.value == :a
    assert A.Zipper.rightmost(A.Zipper.down(zipper)).focus.value == :i
  end

  test "insert_child/2 adds the item as the leftmost child of the current focus, without moving", context do
    zipper = A.Zipper.insert_child(context.zipper, :i)
    assert length(zipper.focus.children) == 4
    assert zipper.focus.value == :a
    assert A.Zipper.down(zipper).focus.value == :i
  end

  test "insert_left/2 adds the item as the left sibling of the current focus, without moving", context do
    zipper = context.zipper |> A.Zipper.down |> A.Zipper.insert_left(:i)
    
    assert zipper.focus.value == :b
    [crumb|_] = zipper.crumbs
    assert crumb.parent.value == :a
    assert Enum.map(crumb.right, &(&1.value)) == [:c, :g]
    assert Enum.map(crumb.left, &(&1.value)) == [:i]

    root = A.Zipper.to_root(zipper)
    assert Enum.map(root.focus.children, &(&1.value)) == [:i, :b, :c, :g]
    
    ## not inserting at 0
    zipper = context.zipper |> A.Zipper.down |> A.Zipper.right |> A.Zipper.insert_left(:i)
    
    assert zipper.focus.value == :c
    [crumb|_] = zipper.crumbs
    assert crumb.parent.value == :a
    assert Enum.map(crumb.right, &(&1.value)) == [:g]
    assert Enum.map(crumb.left, &(&1.value)) == [:b, :i]

    root = A.Zipper.to_root(zipper)
    assert Enum.map(root.focus.children, &(&1.value)) == [:b, :i, :c, :g]
  end

  test "insert_left/2 returns an error if called on the root", context do
    assert A.Zipper.insert_left(context.zipper, :i) == {:error, :root_has_no_siblings}
  end

  test "insert_right/2 adds the item as the right sibling of the current focus, without moving", context do
    zipper = context.zipper |> A.Zipper.down |> A.Zipper.insert_right(:i)
    
    assert zipper.focus.value == :b
    [crumb|_] = zipper.crumbs
    assert crumb.parent.value == :a
    assert Enum.map(crumb.right, &(&1.value)) == [:i, :c, :g]
    assert Enum.map(crumb.left, &(&1.value)) == []

    root = A.Zipper.to_root(zipper)
    assert Enum.map(root.focus.children, &(&1.value)) == [:b, :i, :c, :g]
    
    ## not inserting at 0
    zipper = context.zipper |> A.Zipper.down |> A.Zipper.rightmost |> A.Zipper.insert_right(:i)
    
    assert zipper.focus.value == :g
    [crumb|_] = zipper.crumbs
    assert crumb.parent.value == :a
    assert Enum.map(crumb.right, &(&1.value)) == [:i]
    assert Enum.map(crumb.left, &(&1.value)) == [:b, :c]

    root = A.Zipper.to_root(zipper)
    assert Enum.map(root.focus.children, &(&1.value)) == [:b, :c, :g, :i]
  end

  test "insert_right/2 returns an error if called on the root", context do
    assert A.Zipper.insert_right(context.zipper, :i) == {:error, :root_has_no_siblings}
  end
end
