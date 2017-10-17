defmodule Azalea.Tree do
  @moduledoc """
  `Azalea.Tree` models a rose, or multi-way tree. A rose tree is an `n`-ary (with unbounded `n`) tree 
  where each branch of a node is itself a rose tree. For example:

      iex> Azalea.Tree.new(:a, [:b, :c, Azalea.Tree.new(:d, [:e, :f])])
      %Azalea.Tree{
        value: :a,
        children: [
          %Azalea.Tree{
            value: :b,
            children: []
          },
          %Azalea.Tree{
            value: :c,
            children: []
          },
          %Azalea.Tree{
            value: :d,
            children: [
              %Azalea.Tree{
                value: :e,
                children: []
              },
              %Azalea.Tree{
                value: :f,
                children: []
              },
            ]
          }
        ]
      }

    `Azalea.Tree` nodes are unbalanced and child ordering maintains insertion order. See `add_child/2` and `insert_child/3` below.

  """

  @type t :: %Azalea.Tree{value: any, children: [Azalea.Tree.t]}

  defstruct [:value, :children]

  @doc """

  Returns a tree defined by the arguments passed.

  `new/0` returns an empty tree

      iex> Azalea.Tree.new()
      %Azalea.Tree{
        value: nil,
        children: []
      }
  
  `new/1` returns a tree with the argument assigned as the value, and no children

      iex> Azalea.Tree.new({1, :one, "un"})
      %Azalea.Tree{
        value: {1, :one, "un"},
        children: []
      }

  `new/2` returns a tree with the first argument assigned to the value, and the second argument (a list)
  assigned to the tree's children, with each element wrapped in an `Azalea.Tree`

      iex> Azalea.Tree.new(:a, [:b, :c])
      %Azalea.Tree{
        value: :a,
        children: [
          %Azalea.Tree{
            value: :b,
            children: []
          },
          %Azalea.Tree{
            value: :c,
            children: []
          }
        ]
      }
  
  """
  @spec new(any, [any]) :: Azalea.Tree.t
  def new(value \\ nil, children \\ []) do
    %__MODULE__{value: value, children: wrap_children(children)}
  end

  @doc """

  Returns true if `child` is one of `tree`'s children.

      iex> child = Azalea.Tree.new(:b)
      iex> tree = Azalea.Tree.new(:a, [child])
      iex> Azalea.Tree.is_child?(child, tree)
      true
      iex> Azalea.Tree.is_child?(Azalea.Tree.new(:c), tree)
      false

  """
  @spec is_child?(Azalea.Tree.t, Azalea.Tree.t) :: boolean
  def is_child?(child, tree) do
    Enum.member?(tree, child)
  end

  @doc """

  Appends `child` to the front of `tree`'s children. 

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Azalea.Tree.add_child(tree, Azalea.Tree.new("e"))
      %Azalea.Tree{
        value: :a,
        children: [
          %Azalea.Tree{
            value: "e",
            children: []
          },
          %Azalea.Tree{
            value: :b,
            children: []
          },
          %Azalea.Tree{
            value: :c,
            children: []
          },
          %Azalea.Tree{
            value: :d,
            children: []
          }
        ]
      }

  `add_child/2` will wrap a non-`Azalea.Tree` child in a tree before appending it:

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Azalea.Tree.add_child(tree, "f")
      %Azalea.Tree{
        value: :a,
        children: [
          %Azalea.Tree{
            value: "f",
            children: []
          },
          %Azalea.Tree{
            value: :b,
            children: []
          },
          %Azalea.Tree{
            value: :c,
            children: []
          },
          %Azalea.Tree{
            value: :d,
            children: []
          }
        ]
      }

  This is a shortcut for `Azalea.Tree.insert_child(tree, child, 0)`

  """
  @spec add_child(Azalea.Tree.t, any) :: Azalea.Tree.t
  def add_child(tree = %Azalea.Tree{}, child) do
    insert_child(tree, child, 0)
  end

  @doc """

  Inserts `child` into `tree`'s children at the given `index`.

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Azalea.Tree.insert_child(tree, Azalea.Tree.new("e"), 1)
      %Azalea.Tree{
        value: :a,
        children: [
          %Azalea.Tree{
            value: :b,
            children: []
          },
          %Azalea.Tree{
            value: "e",
            children: []
          },
          %Azalea.Tree{
            value: :c,
            children: []
          },
          %Azalea.Tree{
            value: :d,
            children: []
          }
        ]
      }

  `add_child/2` will wrap a non-`Azalea.Tree` child in a tree before appending it:

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Azalea.Tree.insert_child(tree, "f", -1)
      %Azalea.Tree{
        value: :a,
        children: [
          %Azalea.Tree{
            value: :b,
            children: []
          },
          %Azalea.Tree{
            value: :c,
            children: []
          },
          %Azalea.Tree{
            value: :d,
            children: []
          },
          %Azalea.Tree{
            value: "f",
            children: []
          }
        ]
      }

  """
  @spec insert_child(Azalea.Tree.t, any, integer) :: Azalea.Tree.t
  def insert_child(tree, child, index) do
    with child <- wrap_child(child) do
      %{tree | children: List.insert_at(tree.children, index, child)}
    end
  end

  @doc """

  Removes the tree's first child, and returns a tuple of `{child, tree_without_child}`

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Azalea.Tree.pop_child(tree)
      {
        %Azalea.Tree{value: :b, children: []},
        %Azalea.Tree{
          value: :a,
          children: [
            %Azalea.Tree{
              value: :c,
              children: []
            },
            %Azalea.Tree{
              value: :d,
              children: []
            }
          ]
        }
      }

  """
  @spec pop_child(Azalea.Tree.t) :: {Azalea.Tree.t, Azalea.Tree.t}
  def pop_child(tree = %Azalea.Tree{}) do
    {child, children} = List.pop_at(tree.children, 0)
    {child, %{tree | children: children}}
  end

  @doc """

  Removes the tree's child at the given index and returns a tuple of `{child, tree_without_child}`

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Azalea.Tree.remove_child(tree, 2)
      {
        %Azalea.Tree{value: :d, children: []},
        %Azalea.Tree{
          value: :a,
          children: [
            %Azalea.Tree{
              value: :b,
              children: []
            },
            %Azalea.Tree{
              value: :c,
              children: []
            }
          ]
        }
      }

  """
  @spec remove_child(Azalea.Tree.t, integer) :: {Azalea.Tree.t, Azalea.Tree.t}
  def remove_child(tree = %Azalea.Tree{}, index) do
    {child, children} = List.pop_at(tree.children, index)
    {child, %{tree | children: children}}
  end

  @doc """
  
  Applies a given function to each sub-tree of the tree, maintaining the tree's nested structure

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Azalea.Tree.map(tree, fn t -> %{t | value: "node-" <> to_string(t.value)} end)
      %Azalea.Tree{
        value: "node-a",
        children: [
          %Azalea.Tree{
            value: "node-b",
            children: []
          },
          %Azalea.Tree{
            value: "node-c",
            children: []
          },
          %Azalea.Tree{
            value: "node-d",
            children: []
          }
        ]
      }
  
  Note that this behaves differently than `Enum.map` applied to a tree, which will flatten the tree in depth-first order.

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Enum.map(tree, fn t -> %{t | value: "node-" <> to_string(t.value)} end)
      [
        %Azalea.Tree{
          value: "node-a",
          children: [
            %Azalea.Tree{
              value: :b,
              children: []
            },
            %Azalea.Tree{
              value: :c,
              children: []
            },
            %Azalea.Tree{
              value: :d,
              children: []
            }
          ]
        },
        %Azalea.Tree{
          value: "node-b",
          children: []
        },
        %Azalea.Tree{
          value: "node-c",
          children: []
        },
        %Azalea.Tree{
          value: "node-d",
          children: []
        }
      ]

  """
  @spec map(Azalea.Tree.t, fun) :: Azalea.Tree.t
  def map(tree, fun) do
    %{fun.(tree) | children: Enum.map(tree.children, &map(&1, fun))}
  end

  @doc """

  Returns the total count of `Azalea.Trees` contained in the tree, including the root

      iex> tree = Azalea.Tree.new(:a, [:b, :c, :d])
      iex> Azalea.Tree.length(tree)
      4

  """
  @spec length(Azalea.Tree.t) :: integer
  def length(tree), do: Enum.count(tree)

  @doc """

  Reduces the tree to a single value, using a depth-first walk

      iex> tree = Azalea.Tree.new(:a, [:b, Azalea.Tree.new(:c, [:e, :f]), :d])
      iex> Azalea.Tree.reduce(tree, "", fn t, acc -> acc <> to_string(t.value) end)
      "abcefd"

  """
  @spec reduce(Azalea.Tree.t, term, (term, term -> term)) :: term
  def reduce(tree, acc, fun), do: Enum.reduce(tree, acc, fun)

  @doc """

  Finds a path through `tree` to the `child`.

      iex> tree = Azalea.Tree.new(:a, [:b, Azalea.Tree.new(:c, [:e, :f]), :d])
      iex> Azalea.Tree.path_to(Azalea.Tree.new(:e), tree)
      [
        %Azalea.Tree{
          value: :a,
          children: [
            %Azalea.Tree{
              value: :b,
              children: []
            },
            %Azalea.Tree{
              value: :c,
              children: [
                %Azalea.Tree{
                  value: :e,
                  children: []
                },
                %Azalea.Tree{
                  value: :f,
                  children: []
                }
              ]
            },
            %Azalea.Tree{
              value: :d,
              children: []
            }
          ]
        },
        %Azalea.Tree{
          value: :c,
          children: [
            %Azalea.Tree{
              value: :e,
              children: []
            },
            %Azalea.Tree{
              value: :f,
              children: []
            }
          ]
        },
        %Azalea.Tree{
          value: :e,
          children: []
        }
      ]

  """
  @spec path_to(Azalea.Tree.t, Azalea.Tree.t) :: [Azalea.Tree.t]
  def path_to(child, tree) do
    find_path(tree, child, [])
  end


  ## Private

  defp find_path(tree, target, acc) when tree == target do
    [tree|acc]
  end
  defp find_path(%Azalea.Tree{children: []}, _, _), do: nil
  defp find_path(tree = %Azalea.Tree{children: children}, target, acc) do
    [tree | find_path(children, target, acc)]
  end
  defp find_path(trees, target, acc) when is_list(trees) do
    Enum.find(
      Enum.map(trees, &find_path(&1, target, acc)),
      &(!is_nil(&1))
    )
  end

  defp wrap_children(children) when is_list(children) do
    Enum.map(children, &wrap_child/1)
  end
  defp wrap_child(tree = %__MODULE__{}), do: tree
  defp wrap_child(child), do: new(child)

  @behaviour Access

  @doc """
  Implemenation of the `Access` behaviour. See `Access.fetch/2` for details.
  """
  def fetch(%Azalea.Tree{children: children}, index) when is_integer(index) do
    case Enum.at(children, index) do
      nil -> :error
      child -> {:ok, child}
    end
  end

  @doc """
  Implemenation of the `Access` behaviour. See `Access.get/3` for details.
  """
  def get(tree, index, default \\ nil) when is_integer(index) do
    case fetch(tree, index) do
      {:ok, child} -> child
      :error -> default
    end
  end

  @doc """
  Implemenation of the `Access` behaviour. See `Access.get_and_update/3` for details.
  """
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

  @doc """
  Implemenation of the `Access` behaviour. See `Access.pop/2` for details.
  """
  def pop(tree, index) do
    case get(tree, index) do
      nil -> {nil, tree}
      child -> {child, %{tree | children: List.delete_at(tree.children, index)}}
    end
  end
end
