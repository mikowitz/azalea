defmodule Azalea.Zipper do
  @moduledoc """

  A zipper is an omni-directionally traversable wrapper around a tree that focuses on a single node, but stores enough data
  to be able to reconstruct the entire tree from that point. 
  
  `Azalea.Zipper` provides such a wrapper around `Azalea.Tree`, using a stack of `Azalea.Zipper.Crumb` data structures to retain a 
  history of navigation through the tree. Since a tree holds references to its own children, and a crumb holds references 
  to the tree's parent and siblings, this allows traversal through the tree in any direction by pushing or popping crumbs 
  on to/from the stack.

  See [Huet](https://www.st.cs.uni-saarland.de/edu/seminare/2005/advanced-fp/docs/huet-zipper.pdf) for a more complete definition.

  """
  defmodule Crumb do
    @moduledoc """

    `Azalea.Zipper.Crumb` stores metadata relative to the current focus of a zipper. It maintains a record of the focus's
    parent, and its left and right siblings.

    """

    defstruct [:parent, :left, :right]

    @type t :: %Azalea.Zipper.Crumb{parent: Azalea.Tree.t, left: [Azalea.Tree.t], right: [Azalea.Tree.t]}
  end

  defstruct [:focus, :crumbs]

  @type t :: %Azalea.Zipper{focus: Azalea.Tree.t, crumbs: [Azalea.Tree.Crumb.t]}

  @doc """

  Creates a zipper focused on the given tree

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Azalea.Zipper.from_tree(tree)
      %Azalea.Zipper{
        focus: %Azalea.Tree{
          value: :a,
          children: [
            %Azalea.Tree{value: :b, children: []},
            %Azalea.Tree{value: :c, children: []},
            %Azalea.Tree{value: :d, children: []}
          ]
        },
        crumbs: []
      }

  """
  @spec from_tree(Azalea.Tree.t) :: Azalea.Zipper.t
  def from_tree(tree = %Azalea.Tree{}) do
    %Azalea.Zipper{
      focus: tree,
      crumbs: []
    }
  end

  @doc """

  Returns true if the zipper is currently focused on the root of the tree

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> Azalea.Zipper.is_root?(zipper)
      true
      iex> down_zipper = Azalea.Zipper.down(zipper)
      iex> Azalea.Zipper.is_root?(down_zipper)
      false

  """
  @spec is_root?(Azalea.Zipper.t) :: boolean
  def is_root?(%Azalea.Zipper{crumbs: []}), do: true
  def is_root?(%Azalea.Zipper{crumbs: [%{parent: nil}|_]}), do: true
  def is_root?(%Azalea.Zipper{}), do: false

  @doc """

  Returns true if the zipper is currently focused on the last (depth-first) node in the tree

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> Azalea.Zipper.is_end?(zipper)
      false
      iex> end_zipper = zipper |> Azalea.Zipper.down |> Azalea.Zipper.rightmost
      iex> Azalea.Zipper.is_end?(end_zipper)
      true

  """
  @spec is_end?(Azalea.Zipper.t) :: boolean
  def is_end?(%Azalea.Zipper{focus: %{children: []}, crumbs: [%{right: []}|_]}), do: true
  def is_end?(%Azalea.Zipper{}), do: false

  @doc """
  
  Returns a zipper all the way back up to the tree's root.

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> end_zipper = zipper |> Azalea.Zipper.down |> Azalea.Zipper.rightmost
      iex> end_zipper.focus.value
      :d
      iex> root_zipper = Azalea.Zipper.to_root(end_zipper)
      iex> root_zipper.focus.value
      :a

  """
  @spec to_root(Azalea.Zipper.t) :: Azalea.Zipper.t
  def to_root(zipper = %Azalea.Zipper{}) do
    case is_root?(zipper) do
      true -> zipper
      false -> zipper |> up |> to_root
    end
  end

  @doc """
  
  Moves to the leftmost child of the current focus, or returns an error tuple if there are no children

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> Azalea.Zipper.down(zipper).focus.value
      :b
      iex> zipper |> Azalea.Zipper.down |> Azalea.Zipper.down
      {:error, :no_children}
  
  """
  @spec down(Azalea.Zipper.t) :: Azalea.Zipper.t | {:error, :no_children}
  def down(%Azalea.Zipper{focus: %Azalea.Tree{children: []}}) do
    {:error, :no_children}
  end
  def down(zipper = %Azalea.Zipper{focus: focus = %Azalea.Tree{children: [c|r]}}) do
    %Azalea.Zipper{
      focus: c,
      crumbs: [%Azalea.Zipper.Crumb{
        parent: focus,
        left: [],
        right: r
      }|zipper.crumbs]
    }
  end

  @doc """
  
  Moves focus to the immediate right of the current focus, or returns an error tuple if there is no right sibling

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> Azalea.Zipper.right(zipper)
      {:error, :no_right_sibling}
      iex> zipper = zipper |> Azalea.Zipper.down |> Azalea.Zipper.right
      iex> zipper.focus.value
      :c

  """
  @spec right(Azalea.Zipper.t) :: Azalea.Zipper.t | {:error, :no_right_sibling}
  def right(%Azalea.Zipper{crumbs: []}) do
    {:error, :no_right_sibling}
  end
  def right(%Azalea.Zipper{crumbs: [%Azalea.Zipper.Crumb{right: []}|_]}) do
    {:error, :no_right_sibling}
  end
  def right(zipper = %Azalea.Zipper{}) do
    with crumbs = [crumb|_] <- zipper.crumbs do
      new_left = (crumb.left ++ [zipper.focus])
      [new_focus|new_right] = crumb.right
      new_crumb = %Azalea.Zipper.Crumb{
        left: new_left,
        right: new_right,
        parent: crumb.parent
      }
      %Azalea.Zipper{
        focus: new_focus,
        crumbs: [new_crumb|crumbs]
      }
    end
  end

  @doc """
  
  Moves focus to the parent of the current focus, or returns an error tuple if there is no parent

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> Azalea.Zipper.up(zipper)
      {:error, :no_parent}
      iex> zipper = zipper |> Azalea.Zipper.down 
      iex> zipper.focus.value
      :b
      iex> Azalea.Zipper.up(zipper).focus.value
      :a

  """
  @spec up(Azalea.Zipper.t) :: Azalea.Zipper.t | {:error, :no_parent}
  def up(%Azalea.Zipper{crumbs: []}) do
    {:error, :no_parent}
  end
  def up(%Azalea.Zipper{crumbs: [%Azalea.Zipper.Crumb{parent: nil}|_]}) do
    {:error, :no_parent}
  end
  def up(zipper = %Azalea.Zipper{}) do
    with [crumb|crumbs] <- zipper.crumbs do
      %Azalea.Zipper{
        focus: crumb.parent,
        crumbs: Enum.drop_while(crumbs, fn c -> c.parent == crumb.parent end)
      }
    end
  end

  @doc """
  
  Moves focus to the immediate left of the current focus, or returns an error tuple if there is no left sibling

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree) |> Azalea.Zipper.down
      iex> Azalea.Zipper.left(zipper)
      {:error, :no_left_sibling}
      iex> zipper = zipper |> Azalea.Zipper.right |> Azalea.Zipper.right
      iex> zipper.focus.value
      :d
      iex> Azalea.Zipper.left(zipper).focus.value
      :c

  """
  @spec left(Azalea.Zipper.t) :: Azalea.Zipper.t | {:error, :no_left_sibling}
  def left(%Azalea.Zipper{crumbs: []}) do
    {:error, :no_left_sibling}
  end
  def left(%Azalea.Zipper{crumbs: [%Azalea.Zipper.Crumb{left: []}|_]}) do
    {:error, :no_left_sibling}
  end
  def left(zipper = %Azalea.Zipper{}) do
    with [crumb|crumbs] <- zipper.crumbs do
      new_right = [zipper.focus|crumb.right]
      {new_focus, new_left} = List.pop_at(crumb.left, -1)
      new_crumb = %Azalea.Zipper.Crumb{
        left: new_left,
        right: new_right,
        parent: crumb.parent
      }
      %Azalea.Zipper{
        focus: new_focus,
        crumbs: [new_crumb|crumbs]
      }
    end
  end

  @doc """

  Moves focus to the rightmost sibling of the current focus, or returns the current focus if it is the rightmost

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> Azalea.Zipper.rightmost(zipper).focus.value
      :a
      iex> zipper = zipper |> Azalea.Zipper.down |> Azalea.Zipper.rightmost
      iex> zipper.focus.value
      :d
      iex> Azalea.Zipper.rightmost(zipper).focus.value
      :d

  """
  @spec rightmost(Azalea.Zipper.t) :: Azalea.Zipper.t
  def rightmost(zipper = %Azalea.Zipper{crumbs: []}), do: zipper
  def rightmost(zipper = %Azalea.Zipper{crumbs: [%{right: []}]}), do: zipper
  def rightmost(zipper = %Azalea.Zipper{}) do
    with [crumb|crumbs] <- zipper.crumbs do
      {new_focus, new_left} = List.pop_at(crumb.right, -1)
      new_crumb = %Azalea.Zipper.Crumb{
        parent: crumb.parent,
        right: [],
        left: crumb.left ++ [zipper.focus|new_left]
      }
      %Azalea.Zipper{
        focus: new_focus,
        crumbs: [new_crumb|crumbs]
      }
    end
  end

  @doc """

  Moves focus to the leftmost sibling of the current focus, or returns the current focus if it is the leftmost

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> Azalea.Zipper.leftmost(zipper).focus.value
      :a
      iex> zipper = zipper |> Azalea.Zipper.down |> Azalea.Zipper.leftmost
      iex> zipper.focus.value
      :b

  """
  @spec leftmost(Azalea.Zipper.t) :: Azalea.Zipper.t
  def leftmost(zipper = %Azalea.Zipper{crumbs: []}), do: zipper
  def leftmost(zipper = %Azalea.Zipper{crumbs: [%{left: []}]}), do: zipper
  def leftmost(zipper = %Azalea.Zipper{}) do
    with [crumb|crumbs] <- zipper.crumbs do
      [new_focus|new_right] = crumb.left

      new_crumb = %Azalea.Zipper.Crumb{
        parent: crumb.parent,
        right: new_right ++ [zipper.focus|crumb.right],
        left: []
      }
      %Azalea.Zipper{
        focus: new_focus,
        crumbs: [new_crumb|crumbs]
      }
    end
  end

  @doc """

  Adds a new child as the rightmost child of the current focus, without changing focus

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> zipper = Azalea.Zipper.append_child(zipper, :e)
      iex> zipper.focus.value
      :a
      iex> zipper = zipper |> Azalea.Zipper.down |> Azalea.Zipper.rightmost
      iex> zipper.focus.value
      :e

  """
  @spec append_child(Azalea.Zipper.t, any) :: Azalea.Zipper.t
  def append_child(zipper = %Azalea.Zipper{focus: %Azalea.Tree{}}, child) do
    %Azalea.Zipper{
      focus: Azalea.Tree.insert_child(zipper.focus, child, -1),
      crumbs: zipper.crumbs
    }
  end

  @doc """

  Adds a new child as the leftmost child of the current focus, without changing focus

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> zipper = Azalea.Zipper.insert_child(zipper, :e)
      iex> zipper.focus.value
      :a
      iex> zipper = zipper |> Azalea.Zipper.down |> Azalea.Zipper.leftmost
      iex> zipper.focus.value
      :e

  """
  @spec insert_child(Azalea.Zipper.t, any) :: Azalea.Zipper.t
  def insert_child(zipper = %Azalea.Zipper{focus: %Azalea.Tree{}}, child) do
    %Azalea.Zipper{
      focus: Azalea.Tree.insert_child(zipper.focus, child, 0),
      crumbs: zipper.crumbs
    }
  end

  @doc """

  Adds a new sibling immediately to the left of the current focus, without changing focus

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> zipper = Azalea.Zipper.down(zipper)
      iex> zipper.focus.value
      :b
      iex> zipper = zipper |> Azalea.Zipper.insert_left(:e)
      iex> zipper.focus.value
      :b
      iex> Azalea.Zipper.left(zipper).focus.value
      :e

  """
  @spec insert_left(Azalea.Zipper.t, any) :: Azalea.Zipper.t | {:error, :root_has_no_siblings}
  def insert_left(%Azalea.Zipper{crumbs: []}, _), do: {:error, :root_has_no_siblings}
  def insert_left(%Azalea.Zipper{crumbs: [%{parent: nil}|_]}, _), do: {:error, :root_has_no_siblings}
  def insert_left(zipper = %Azalea.Zipper{}, sibling) do
    [crumb|crumbs] = zipper.crumbs
    new_parent = Azalea.Tree.insert_child(crumb.parent, sibling, length(crumb.left))
    new_left = crumb.left ++ [Enum.at(new_parent.children, length(crumb.left))]
    new_crumb = %{crumb | parent: new_parent, left: new_left}
    new_crumbs = Enum.map(crumbs, fn c ->
      case c.parent == crumb.parent do
        true -> %{c | parent: new_parent}
        false -> c
      end
    end)
    %{zipper | crumbs: [new_crumb|new_crumbs]}
  end

  @doc """

  Adds a new sibling immediately to the right of the current focus, without changing focus

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> zipper = Azalea.Zipper.from_tree(tree)
      iex> zipper = Azalea.Zipper.down(zipper)
      iex> zipper.focus.value
      :b
      iex> zipper = zipper |> Azalea.Zipper.insert_right(:e)
      iex> zipper.focus.value
      :b
      iex> Azalea.Zipper.right(zipper).focus.value
      :e

  """
  @spec insert_right(Azalea.Zipper.t, any) :: Azalea.Zipper.t | {:error, :root_has_no_siblings}
  def insert_right(%Azalea.Zipper{crumbs: []}, _), do: {:error, :root_has_no_siblings}
  def insert_right(%Azalea.Zipper{crumbs: [%{parent: nil}|_]}, _), do: {:error, :root_has_no_siblings}
  def insert_right(zipper = %Azalea.Zipper{}, sibling) do
    [crumb|crumbs] = zipper.crumbs
    new_sibling_index = length(crumb.left) + 1
    new_parent = Azalea.Tree.insert_child(crumb.parent, sibling, new_sibling_index)
    new_right = [Enum.at(new_parent.children, new_sibling_index)|crumb.right]
    new_crumb = %{crumb | parent: new_parent, right: new_right}
    new_crumbs = Enum.map(crumbs, fn c ->
      case c.parent == crumb.parent do
        true -> %{c | parent: new_parent}
        false -> c
      end
    end)
    %{zipper | crumbs: [new_crumb|new_crumbs]}
  end
end
