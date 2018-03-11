defmodule Absinthe.Blueprint.Schema.ObjectTypeDefinition do
  @moduledoc false

  alias Absinthe.Blueprint

  @enforce_keys [:name, :identifier]
  defstruct [
    :name,
    :identifier,
    description: nil,
    interfaces: [],
    fields: [],
    directives: [],
    # Added by phases
    flags: %{},
    imports: [],
    errors: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          identifier: atom,
          description: nil | String.t(),
          fields: [Blueprint.Schema.FieldDefinition.t()],
          interfaces: [String.t()],
          directives: [Blueprint.Directive.t()],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()]
        }

  def build(type_def, schema) do
    %Absinthe.Type.Object{
      identifier: type_def.identifier,
      name: type_def.name,
      fields: build_fields(type_def, schema.module)
    }
  end

  def build_fields(type_def, module) do
    for field_def <- type_def.fields, into: %{} do
      # TODO: remove and make middleware work generally
      middleware_shim = {
        {__MODULE__, :shim},
        {module, type_def.identifier, field_def.identifier}
      }

      attrs =
        field_def
        |> Map.from_struct()
        |> Map.put(:middleware, [middleware_shim])

      field = struct(Absinthe.Type.Field, attrs)

      {field.identifier, field}
    end
  end

  def shim(res, {module, obj, field}) do
    middleware = apply(module, :__absinthe_middleware__, [obj, field])
    %{res | middleware: middleware}
  end
end
