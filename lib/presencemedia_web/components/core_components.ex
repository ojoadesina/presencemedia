defmodule PresencemediaWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  Styling is hand-written Tailwind against the house palette in `app.css` —
  there is no component library underneath, so what you read here is what
  renders. Four rules keep the set coherent:

    * SURFACES come from two ramps, not one: `light-*` (warm, cream to cocoa)
      and `dark-*` (black and untinted greys). Every colour utility therefore
      ships with a `dark:` twin, and they run in OPPOSITE directions. Light's
      page is `light-50` and everything real on it is darker; dark's page is
      `dark-950` and everything real on it is lighter. Never pair them by
      number — `text-light-900 dark:text-dark-100` is a matched pair, and
      `dark:text-dark-900` on the dark page would be invisible.
    * `primary` (terracotta) means ATTENTION — the pressed button, the invalid
      field, the error flash. The palette carries no separate red, and it does
      not need one.
    * `secondary` (sage) means AFFIRMATION — the info flash. It is also the
      presence dot's colour, so spend it sparingly.
    * SIZES come from the custom type scale, which is tighter than Tailwind's
      stock ramp — `text-md` here is 0.875rem, and `text-xl` is 1rem, not
      1.25rem. Never assume a stock size means what it usually means.

  Useful references:

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  # Every input type shares one shell, so a text field and a select can never
  # drift apart on border, radius, focus ring or disabled treatment.
  #
  # These are FUNCTIONS, not module attributes, because inside ~H the `@name`
  # form always means `assigns.name` — a module attribute referenced that way in
  # a template silently becomes a missing-assign crash at render time.
  defp input_base do
    "w-full rounded-md border bg-light-50 px-3 py-2 text-md text-light-900 " <>
      "placeholder:text-light-400 transition-colors outline-none " <>
      "focus-visible:ring-2 focus-visible:ring-primary-500/40 " <>
      "disabled:cursor-not-allowed disabled:opacity-50 " <>
      "dark:bg-dark-900 dark:text-dark-100 dark:placeholder:text-dark-500"
  end

  defp input_ok do
    "border-light-200 focus-visible:border-primary-500 dark:border-dark-800"
  end

  defp input_bad do
    "border-primary-600 focus-visible:border-primary-600 dark:border-primary-500"
  end

  # The label above every field. One definition so a select and a text input can
  # never disagree about weight or spacing.
  defp field_label do
    "mb-1 block text-sm font-medium text-light-700 dark:text-dark-300"
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="fixed top-4 right-4 z-50 w-80 cursor-pointer sm:w-96"
      {@rest}
    >
      <div class={[
        "flex items-start gap-3 rounded-lg border p-4 text-md shadow-lg text-wrap",
        @kind == :info &&
          "border-secondary-200 bg-secondary-50 text-secondary-900 dark:border-secondary-800 dark:bg-secondary-950 dark:text-secondary-100",
        @kind == :error &&
          "border-primary-200 bg-primary-50 text-primary-900 dark:border-primary-800 dark:bg-primary-950 dark:text-primary-100"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div class="flex-1">
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <button type="button" class="group cursor-pointer self-start" aria-label="close">
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    base =
      "inline-flex cursor-pointer items-center justify-center gap-2 rounded-md px-4 py-2 " <>
        "text-md font-semibold transition-colors outline-none " <>
        "focus-visible:ring-2 focus-visible:ring-primary-500/40 focus-visible:ring-offset-2 " <>
        "focus-visible:ring-offset-light-50 dark:focus-visible:ring-offset-dark-950 " <>
        "disabled:pointer-events-none disabled:opacity-50"

    # Solid carries the page's one primary action. Soft is the same colour at low
    # ink, so a row of secondary actions reads as a group rather than as noise.
    variants = %{
      "primary" =>
        "bg-primary-600 text-primary-50 hover:bg-primary-700 dark:bg-primary-500 dark:hover:bg-primary-600",
      nil =>
        "bg-primary-100 text-primary-800 hover:bg-primary-150 dark:bg-primary-950 dark:text-primary-200 dark:hover:bg-primary-900"
    }

    assigns =
      assign_new(assigns, :class, fn ->
        [base, Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="mb-2">
      <label class="flex items-center gap-2 text-md text-light-900 dark:text-dark-100">
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={
            @class ||
              "size-4 shrink-0 cursor-pointer rounded border-light-300 accent-primary-600 " <>
                "outline-none focus-visible:ring-2 focus-visible:ring-primary-500/40 " <>
                "dark:border-dark-700 dark:accent-primary-500"
          }
          {@rest}
        />{@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="mb-2">
      <label>
        <span :if={@label} class={field_label()}>{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class || [input_base(), "cursor-pointer"],
            @errors == [] && !@class && input_ok(),
            @errors != [] && (@error_class || input_bad())
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="mb-2">
      <label>
        <span :if={@label} class={field_label()}>{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || [input_base(), "min-h-24"],
            @errors == [] && !@class && input_ok(),
            @errors != [] && (@error_class || input_bad())
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="mb-2">
      <label>
        <span :if={@label} class={field_label()}>{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || input_base(),
            @errors == [] && !@class && input_ok(),
            @errors != [] && (@error_class || input_bad())
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex items-center gap-2 text-sm text-primary-700 dark:text-primary-400">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-3xl font-semibold leading-8 text-light-900 dark:text-dark-100">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-md text-light-600 dark:text-dark-400">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <%!-- The wrapper is what keeps a wide table from pushing the PAGE sideways:
         it scrolls inside its own box instead. --%>
    <div class="w-full overflow-x-auto">
      <table class="w-full border-collapse text-left text-md">
        <thead class="border-b border-light-200 dark:border-dark-800">
          <tr>
            <th
              :for={col <- @col}
              class="p-3 text-sm font-semibold tracking-wide text-light-600 uppercase dark:text-dark-400"
            >
              {col[:label]}
            </th>
            <th :if={@action != []} class="p-3">
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}
          class="text-light-900 dark:text-dark-100"
        >
          <%!-- Zebra striping by hand. nth-child on the ROW rather than a class on
               each cell, so a stream insert cannot land on the wrong colour. --%>
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class="border-b border-light-150 odd:bg-light-100/50 hover:bg-primary-50 dark:border-dark-800 dark:odd:bg-dark-900/40 dark:hover:bg-primary-950/40"
          >
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={["p-3", @row_click && "hover:cursor-pointer"]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="w-0 p-3 font-semibold">
              <div class="flex gap-4">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="divide-y divide-light-200 dark:divide-dark-800">
      <li :for={item <- @item} class="flex flex-col gap-1 py-4">
        <div class="text-sm font-semibold tracking-wide text-light-600 uppercase dark:text-dark-400">
          {item.title}
        </div>
        <div class="text-md text-light-900 dark:text-dark-100">{render_slot(item)}</div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a LEFT PRESENCE — one someone recorded and left behind.

  ## The shape

  An outer rectangle holding an inner one. The inner rectangle is not a
  highlight sitting behind something else — it IS the content, and it carries
  the colour. For voice it doubles as the player: it fills left to right as the
  recording runs, so the thing you are looking at and the thing telling you
  where you are in it are the same object rather than a bar bolted underneath.

  Square corners, because nothing on this surface is rounded — the reference this
  came from is rounded, and that is the one detail deliberately not carried over.

  ## Left is not live

  The frame in the list carries a LIVE presence: no duration, no shape, only
  breathing, because you cannot see the length of something still happening. A
  left presence is finished, so it has both — and the fill is what having a
  length looks like.

  ## Face slots into the same rectangle

  The inner rectangle is a REGION. Voice fills it with colour advancing; face
  will fill it with a still. The outer rectangle, the press target and the fill
  that tracks position do not change when its contents do.

  ## Examples

      <.presence presence={@moment} id="p-1" />
  """
  attr :id, :string, required: true
  attr :presence, :map, required: true

  def presence(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="Waveform"
      phx-update="ignore"
      data-media={@presence.media}
      role="button"
      tabindex="0"
      aria-label={"Play #{@presence.len} recording"}
      class={["presence", !@presence.heard && "is-unheard"]}
    >
      <div class="presence-inner">
        <div class="presence-fill"></div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the mark: a head, face on, eyes open.

  It is the whole argument of the product in one shape — people are the primary
  focus — so it is a FACE rather than a monogram or a glyph of a network. Two
  eyes on a circle is the least you can draw that a person reads as another
  person looking back.

  `animated` blinks it. The blink is long-cycle and single-frame on purpose: a
  logo that blinks often is a logo that nags, but one that blinks occasionally
  is alive in peripheral vision, which is exactly the claim the mark is making.
  Pass `animated={false}` where stillness matters — a favicon, a print sheet, a
  dense list of many marks.

  ## Examples

      <.head />
      <.head class="h-8 text-primary-600" animated={false} />
  """
  attr :class, :string, default: "h-20 text-primary-500"
  attr :animated, :boolean, default: true
  attr :rest, :global

  def head(assigns) do
    ~H"""
    <svg
      class={["head", @animated && "is-animated", @class]}
      viewBox="50.8 0 298 400"
      fill="none"
      aria-hidden="true"
      {@rest}
    >
      <g class="head-face">
        <circle cx="199.8" cy="197.8" r="149" fill="currentColor" />
        <g class="head-eyes">
          <circle cx="108.6" cy="231.3" r="18" fill="#000000" />
          <circle cx="291" cy="231.3" r="18" fill="#000000" />
        </g>
      </g>
    </svg>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # You can make use of gettext to translate error messages by
    # uncommenting and adjusting the following code:

    # if count = opts[:count] do
    #   Gettext.dngettext(PresencemediaWeb.Gettext, "errors", msg, msg, count, opts)
    # else
    #   Gettext.dgettext(PresencemediaWeb.Gettext, "errors", msg, opts)
    # end

    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
