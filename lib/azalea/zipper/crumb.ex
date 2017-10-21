defmodule Azalea.Zipper.Crumb do
  @moduledoc """
  `Azalea.Zipper.Crumb` stores metadata relative to the current focus of a zipper. It maintains a record of the focus's
  parent, and its left and right siblings.
  """

  alias Azalea.{Tree, Zipper.Crumb}

  defstruct [:parent, :left, :right]

  @type t :: %Crumb{parent: Tree.t, left: [Tree.t], right: [Tree.t]}
end
