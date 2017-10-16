defmodule Azalea.Zipper do
  defmodule Crumb do
    defstruct [:parent, :left, :right]
  end

  defstruct [:focus, :crumbs]

  def from_tree(tree = %Azalea.Tree{}) do
    %Azalea.Zipper{
      focus: tree,
      crumbs: []
    }
  end

  def is_root?(%Azalea.Zipper{crumbs: []}), do: true
  def is_root?(%Azalea.Zipper{crumbs: [%{parent: nil}|_]}), do: true
  def is_root?(%Azalea.Zipper{}), do: false

  def is_end?(zipper = %Azalea.Zipper{}) do
    root = to_root(zipper).focus
    zipper.focus == Enum.map(root, &(&1)) |> List.last
  end

  def to_root(zipper = %Azalea.Zipper{}) do
    case is_root?(zipper) do
      true -> zipper
      false -> zipper |> up |> to_root
    end
  end

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
end
