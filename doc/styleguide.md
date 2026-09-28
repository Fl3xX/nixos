# Style guide

Use this page as a reference and style guide for our internal and external documentation.

## Syntax

As per [RFC 0072](https://github.com/NixOS/rfcs/pull/72), all new documentation content should be written in [CommonMark](https://commonmark.org/) Markdown dialect.

Additional syntax extensions are available, all of which can be used in NixOS option documentation.
The following extensions are currently used:

#### Tables

Tables, using the [GitHub-flavored Markdown syntax](https://github.github.com/gfm/#tables-extension-).

#### Anchors

Explicitly defined **anchors** on headings, to allow linking to sections.
These should be always used, to ensure the anchors can be linked even when the heading text changes, and to prevent conflicts between [automatically assigned identifiers](https://github.com/jgm/commonmark-hs/blob/master/commonmark-extensions/test/auto_identifiers.md).

It uses the widely compatible [header attributes](https://github.com/jgm/commonmark-hs/blob/master/commonmark-extensions/test/attributes.md) syntax:

```markdown
## Syntax {#sec-contributing-markup}
```

> [!Note]
> NixOS option documentation does not support headings in general.

#### Inline Anchors

Allow linking to an arbitrary place in the text (e.g. individual list items, sentences…).

They are defined using a hybrid of the link syntax with the attributes syntax known from headings, called [bracketed spans](https://github.com/jgm/commonmark-hs/blob/master/commonmark-extensions/test/bracketed_spans.md):

```markdown
- []{#ssec-gnome-hooks-glib} `glib` setup hook will populate `GSETTINGS_SCHEMAS_PATH` and then `wrapGApps*` hook will prepend it to `XDG_DATA_DIRS`.
```

#### Automatic links

If you **omit a link text** for a link pointing to a section, the text will be substituted automatically.
For example `[](#chap-contributing)`.

This syntax is taken from [MyST](https://myst-parser.readthedocs.io/en/latest/using/syntax.html#targets-and-cross-referencing).


#### HTML

Inlining HTML is not allowed.
Parts of the documentation get rendered to various non-HTML formats, such as man pages in the case of NixOS manual.

#### Roles

If you want to link to a man page, you can use `` {manpage}`nix.conf(5)` ``.
The references will turn into links when a mapping exists in [`doc/manpage-urls.json`](./manpage-urls.json).
Please keep the `manpage-urls.json` file alphabetically sorted.

A few markups for other kinds of literals are also available:

- `` {command}`rm -rfi` ``
- `` {env}`XDG_DATA_DIRS` ``
- `` {file}`/etc/passwd` ``
- `` {option}`networking.useDHCP` ``
- `` {var}`pkgs` ``

The values will be formatted as inline `<code>` elements.

These literal kinds are used mostly in NixOS option documentation.

#### Admonitions

Set off from the text to bring attention to something.

It uses pandoc’s [fenced `div`s syntax](https://github.com/jgm/commonmark-hs/blob/master/commonmark-extensions/test/fenced_divs.md):

```markdown
::: {.warning}
This is a warning
:::
```

The following are supported:

- `caution`
- `important`
- `note`
- `tip`
- `warning`
- `example`

Example admonitions require a title to work.
If you don't provide one, the manual won't build.

```markdown
::: {.example #ex-showing-an-example}

# Title for this example

Text for the example.
:::
```

#### [Definition lists](https://github.com/jgm/commonmark-hs/blob/master/commonmark-extensions/test/definition_lists.md)

For defining a group of terms:

```markdown
Pear
:   Green or yellow bulbous fruit

Watermelon
:   Green fruit with red flesh
```

## Documentation conventions

In an effort to keep the Nixpkgs manual in a consistent style, please follow the conventions below, unless they prevent you from properly documenting something.
In that case, please open an issue about the particular documentation convention and tag it with a "needs: documentation" label.
When needed, each convention explains why it exists, so you can make a decision whether to follow it or not based on your particular case.
Note that these conventions are about the **structure** of the manual (and its source files), not about the content that goes in it.
You, as the writer of documentation, are still in charge of its content.

**For prose style, see the [documentation style guide](./styleguide.md).**

### Document structure

Organize each chapter as guide sections first, then a single `## Reference` section.

A well-structured chapter looks like this:

````markdown
# Foo {#foo}

`foo` builds Foo projects from a `foo.toml`.

## Package a Foo application {#foo-packaging}

:::{.example #ex-foo-packaging}

# Package the hello app

```nix
{ foo }:
buildFooPackage {
  pname = "hello";
  version = "1.0";
}
```

:::

`buildFooPackage` needs `pname` and `version`.
Keep explanation short, and place it after the example.

## Reference {#foo-reference}

### `buildFooPackage` {#foo-buildFooPackage}

Builds a Foo application from source.

#### Inputs {#foo-buildFooPackage-inputs}

`pname` (String)
: The program name.

#### Examples {#foo-buildFooPackage-examples}

See [](#ex-foo-packaging).
````

Follow this structure strictly; to deviate, ping @NixOS/documentation-team.


### One sentence per line

Put each sentence in its own line.
This makes reviews and suggestions much easier, since GitHub's review system is based on lines.
It also helps identifying long sentences at a glance.

Not everything has been migrated to this format yet.
Please always use it for new content.
When changing existing content, update formatting if possible, but avoid excessive diffs.

### Examples first

Put examples before detailed explanations (see the [style guide](./styleguide.md) for the rationale).

Use this structure for each documented item:

1. Title
2. Abstract (optional, one sentence max)
3. Example
4. Explanation (details, edge cases, types, defaults)

Rendered example:

````markdown
## `lib.toUpper`

Converts all characters in a string to uppercase.

:::{.example #ex-lib-toUpper}
# Converting a string to uppercase
```nix
lib.toUpper "hello"
=> "HELLO"
```

:::

Only acts on ASCII characters.
Unicode characters are passed through unchanged.
````

### Writing Function Documentation

Function documentation is *reference documentation*, for which
[diataxis Reference documentation](https://diataxis.fr/reference/) (8 minutes) is **mandatory reading**.

On top of the diataxis framework, which provides a balanced perspective on what reference documentation should contain, we apply a specific style rule to function documentation:
the first sentence is in present tense, active voice, and the subject is omitted, referring implicitly to the name of the function.
For example:

```nix
/**
  Subtracts value `b` from value `a`.

  Returns the difference as a number.
*/
subtractValues # ...elided code
```

Renders as:

```md
## `subtractValues`

Subtracts value `b` from value `a`.

Returns the difference as a number.
```

### Callouts and examples

Use the [admonition syntax](#admonitions) for callouts and examples.

### `callPackage`-compatible examples

Provide at least one example per function, in its doc-comment.

Keep each example at the level it documents:

- A **reference example** might sometimes live in a doc-comment and show function call shape.
- A **guide example** lives in a guide section and shows a complete task that may compose several functions.

When the task is nothing more than the call itself, the guide example is enough.
The reference example links to the guide example.

Example code should be such that it can be passed to `pkgs.callPackage`.
Instead of something like:

```nix
pkgs.dockerTools.buildLayeredImage {
  name = "hello";
  contents = [ pkgs.hello ];
}
```

Write something like:

```nix
{ dockerTools, hello }:
dockerTools.buildLayeredImage {
  name = "hello";
  contents = [ hello ];
}
```

### REPLs

When showing inputs/outputs of any [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop), such as a shell or the Nix REPL, use a format as you'd see in the REPL, while trying to visually separate inputs from outputs.
This means that for a shell, you should use a format like the following:
```shell
$ nix-build -A hello '<nixpkgs>' \
  --option require-sigs false \
  --option trusted-substituters file:///tmp/hello-cache \
  --option substituters file:///tmp/hello-cache
/nix/store/zhl06z4lrfrkw5rp0hnjjfrgsclzvxpm-hello-2.12.1
```
Note how the input is preceded by `$` on the first line and indented on subsequent lines, and how the output is provided as you'd see on the shell.

For the Nix REPL, you should use a format like the following:
```shell
nix-repl> builtins.attrNames { a = 1; b = 2; }
[ "a" "b" ]
```
Note how the input is preceded by `nix-repl>` and the output is provided as you'd see on the Nix REPL.

### Headings for inputs, outputs and examples

When documenting functions or anything that has inputs/outputs and example usage, use nested headings to clearly separate inputs, outputs, and examples.
Keep examples as the last nested heading, and link to the examples wherever applicable in the documentation.

The purpose of this convention is to provide a familiar structure for navigating the manual, so any reader can expect to find content related to inputs in an "inputs" heading, examples in an "examples" heading, and so on.
An example:
```
## buildImage

Some explanation about the function here.
Describe a particular scenario, and point to [](#ex-dockerTools-buildImage), which is an example demonstrating it.

### Inputs

Documentation for the inputs of `buildImage`.
Perhaps even point to [](#ex-dockerTools-buildImage) again when talking about something specifically linked to it.

### Passthru outputs

Documentation for any passthru outputs of `buildImage`.

### Examples

Note that this is the last nested heading in the `buildImage` section.

:::{.example #ex-dockerTools-buildImage}

# Using `buildImage`

Example of how to use `buildImage` goes here.

:::
```

### Function arguments

Use [definition lists](#definition-lists) to document function arguments, and the attributes of such arguments as well as their [types](https://nixos.org/manual/nix/stable/language/values).
For example:

```markdown
# pkgs.coolFunction {#pkgs.coolFunction}

`pkgs.coolFunction` *`name`* *`config`*

Description of what `callPackage` does.


## Inputs {#pkgs-coolFunction-inputs}

If something's special about `coolFunction`'s general argument handling, you can say so here.
Otherwise, just describe the single argument or start the arguments' definition list without introduction.

*`name`* (String)

: The name of the resulting image.

*`config`* (Attribute set)

: Introduce the parameter. Maybe you have a test to make sure `{ }` is a sensible default; then you can say: these attributes are optional; `{ }` is a valid argument.

  `outputHash` (String; _optional_)

  : A brief explanation including when and when not to pass this attribute.

  : _Default:_ the output path's hash.
```

Checklist:
- Start with a synopsis, to show the order of positional arguments.
- Metavariables are in emphasized code spans: ``` *`arg1`* ```.
  Metavariables are placeholders where users may write arbitrary expressions.
  This includes positional arguments.
- Attribute names are regular code spans: ``` `attr1` ```.
  These identifiers can _not_ be picked freely by users, so they are _not_ metavariables.
- _optional_ attributes have a _`Default:`_ if it's easily described as a value.
- _optional_ attributes have a _`Default behavior:`_ if it's not easily described using a value.
- Nix types aren't in code spans, because they are not code
- Nix types are capitalized, to distinguish them from the camelCase Module System types, which _are_ code and behave like functions.

#### Examples

To define a referenceable figure use the following fencing:

```markdown
:::{.example #an-attribute-set-example}
# An attribute set example

You can add text before

    ```nix
    { a = 1; b = 2;}
    ```

and after code fencing
:::
```

Defining examples through the `example` fencing class adds them to a "List of Examples" section after the Table of Contents.
Though this is not shown in the rendered documentation on nixos.org.

#### Figures

To define a referenceable figure use the following fencing:

```markdown
::: {.figure #nixos-logo}
# NixOS Logo
![NixOS logo](./nixos_logo.png)
:::
```

Defining figures through the `figure` fencing class adds them to a `List of Figures` after the `Table of Contents`.
Though this is not shown in the rendered documentation on nixos.org.

#### Footnotes

To add a footnote explanation, use the following syntax:

```markdown
Sometimes it's better to add context [^context] in a footnote.

[^context]: This explanation will be rendered at the end of the chapter.
```

#### Inline comments

Inline comments are supported with following syntax:

```markdown
<!-- This is an inline comment -->
```

The comments will not be rendered in the rendered HTML.

#### Link reference definitions

Links can reference a label, for example, to make the link target reusable:

```markdown
::: {.note}
Reference links can also be used to [shorten URLs][url-id] and keep the markdown readable.
:::

[url-id]: https://github.com/NixOS/nixpkgs/blob/19d4f7dc485f74109bd66ef74231285ff797a823/doc/README.md
```

This syntax is taken from [CommonMark](https://spec.commonmark.org/0.30/#link-reference-definitions).

#### Typographic replacements

Typographic replacements are enabled.
Check the [list of possible replacement patterns](https://github.com/executablebooks/markdown-it-py/blob/3613e8016ecafe21709471ee0032a90a4157c2d1/markdown_it/rules_core/replacements.py#L1-L15).
## Assumptions about the reader

**Assume competence, not familiarity.**

Write for someone who knows a great deal — up to but not including this project.

**What readers know:**

- Basic computer operation
- Command line familiarity
- General interest in systems configuration

**What readers don't know:**

- NixOS-specific concepts
- NixOS ecosystem details or grammar
- NixOS workflows

If specific knowledge is required, mention it at the start of the page.

### Show, Don't Tell

The fastest path to understanding is a working example.
People learn by doing, not by reading about doing.

**Recommended structure:**

- Start with the minimal working code or command
- Briefly explain what it does
- Cover edge cases or variations
- Link to further information instead of including it

### Grammar and Style

**Sentence structure:**

- Use simple, direct sentences
- Break complex ideas into multiple short sentences
- Avoid nested clauses

**Bad:**

> The following command, which utilizes nixos-generate-config to produce a comprehensive hardware configuration, will write the results back into the respective configuration directory located on your local machine.

What the user does is hidden in the middle.
`nixos-generate-config` is a leaked implementation detail.
Users care about *detecting hardware*, not *the tool that does it*.

**Good:**

> This command detects your hardware and saves the configuration.

### Content Organization

Lead with value. State what the reader will accomplish before explaining how.

**Bad:**

> To create a new NixOS configuration that you can later use as a webserver, first navigate to your project directory, then add a new host configuration file with the desired machine name.

**Good:**

Add a webserver configuration to your NixOS setup:

```nix
# hosts/webserver/configuration.nix
{ ... }:
{
  services.nginx.enable = true;
}
```

Use **progressive disclosure**. Introduce concepts only when needed.

**Recommended structure:**

1. State the goal (one sentence)
2. Show the simplest working example
3. Explain concepts if needed
4. Provide advanced options separately or link to the reference

### No Meta-commentary

Don't describe what the documentation does. Just do it.

**Don't:**

> This section explains how to configure networking.

> The following guide walks you through setting up a web server.

**Do:**

> Configure networking by setting:

> Set up a web server:

### Code Examples

**Keep examples focused:**

- Show one concept at a time
- Use realistic but simple scenarios
- Avoid dependencies on other examples

**Minimal comments**

Let the code speak for itself.
Paste code examples directly and without further alteration.

**Bad:**

```nix
# This sets the hostname for the machine
{
  networking.hostName = "webserver"; # Change this to your machine's hostname
  # This enables SSH access
  services.openssh.enable = true; # Required for remote deployment
}
```

**Good:**

```nix
{
  networking.hostName = "webserver";
  services.openssh.enable = true;
}
```

### Lead with Practical Examples

Don't front-load theory. Readers want to accomplish something first, then understand why it works.

- Show configuration as *what you want*, not *how the module system works*
- Introduce Nix-specific concepts only when they are needed to complete the task
- Defer language mechanics to reference pages or `nix.dev`

**Bad:**

> Before adding a service, you need to understand the NixOS module system and attribute set merging.

**Good:**

Enable nginx:

```nix
{ services.nginx.enable = true; }
```

This adds nginx to your system configuration. Rebuild to apply:

```bash
sudo nixos-rebuild switch
```

### Teach Nix through examples, not theory


Users learn the NixOS module system by seeing patterns first.

- Start with a working example
- Explanation follows the code
- Link deeper concepts instead of inlining them
- Link to `nix.dev` for optional learning

### General Rules

- Abbreviate keys like `ssh-ed25519 AAAAC3NzaC…`
- Abbreviate IP addresses like `192.168.XXX.XXX`
- Variables are capitalized and start with `$`, e.g. `$YOUR_HOSTNAME`
- Variables should be directly usable during copy-paste
- Do **not** describe missing code parts (`#elided`, `#omitted`)
- **Machine vs Host**: use "machine" for the NixOS system identity, "host" for the physical or virtual hardware

### Capitalization

- GB / RAM / HDD
- bootable USB drive
- Wi-Fi / DHCP / DNS
- macOS / NixOS / Nix / Linux
- Flakes
- git

### Headings

Use sentence case. A reader scanning only headings should understand the page.

**Don't:**

> Getting Started
> Overview
> Configure The Database

**Do:**

> Set up a PostgreSQL database
> Configure networking
> Add a user to the system

### Imperative Mood, Voice, and Person

Use imperative mood for instructions. Address the reader as "you", not "the user". Use active voice; in other words, make the subject do the action.

**Don't:**

> The user should run the following command.
> The configuration will need to be updated.
> The key is generated by the system.

**Do:**

> Run the command.
> Update the configuration.
> The system generates the key.

### Tense

Use present tense for descriptions. Future tense makes documentation feel tentative.

**Don't:**

> This will create a new folder.
> Running this command will install the package.

**Do:**

> This creates a new folder.
> Running this command installs the package.

### Be Confident

State facts. Don't hedge with "should," "might," "typically," or "usually" unless the behavior genuinely varies.

**Don't:**

> This should create the configuration file.
> The service will usually start automatically.

**Do:**

> This creates the configuration file.
> The service starts automatically.

### Avoid Nominalizations

A nominalization is a verb turned into a noun, often by adding *-tion*, *-meant*, or *-ance* (e.g. "explanation", "selection"). The fix: find the hidden verb and use it directly.

**Don't:**

> Make a selection from the list.
> Provide an explanation of the error.

**Do:**

> Select from the list.
> Explain the error.

### Plain Words

Technical precision for technical terms; plain language for everything else.

- "use" not "utilize"
- "start" not "initiate"
- "end" not "terminate"
- "help" not "facilitate"
- "send" not "transmit"
- "set up" not "establish"
- "find out" not "ascertain"

### Filler Words and Weak Phrases

Cut words and phrases that add length without meaning.

Delete on sight:

- "simply", "just", "easily", "basically", "obviously"
- "in order to" → use "to"
- "allows you to" → use the verb directly
- "it's worth noting that" → just say the thing
- no exclamation marks in technical prose

**Don't:**

> Simply run `nixos-rebuild switch`.
> In order to deploy, you first need to run the command, which allows you to push the config.
> It's worth noting that this requires root access.

**Do:**

> Run `nixos-rebuild switch`.
> To deploy, run:
> This requires root access.

Every word must earn its place.

### Writing Procedures

One instruction per sentence. Don't pack multiple actions into one sentence.

**Don't:**

> Navigate to your project directory and run the command, then check the output.

**Do:**

1. Navigate to your project directory.
2. Run the command.
3. Check the output.

Don't bury the negative. Key limitations should be prominent, not a footnote after a positive description.

**Don't:**

> This service supports multiple roles, integrates with existing modules, and works great for most setups (note that multiple instances are not supported).

**Do:**

> This service does not support multiple instances.

### Consistent Terminology

Pick a term and stick to it. Don't swap synonyms to avoid repetition. In technical documentation, repetition is clarity.

**Don't:**

> Create a machine... configure the host... deploy the node.

**Do:**

> Create a machine... configure the machine... deploy the machine.

### Links

Use descriptive link text. Never use "click here" or "this link."

**Don't:**

> For more information, see `[this page](url)`.
> Click `[here](url)` to read the reference.

**Do:**

> See the `[NixOS options reference](url)` for details.
> Read the `[NixOS module system guide](url)`.

Only link when the destination is directly relevant, not for generic background context (sometimes known as "Wikipedia-style links"). Readers feel obligated to click links, fearing they'll miss something important. Don't send them to a generic article about a technology when they're looking for how *your* system uses it.

**Don't:**

> Our software uses [SQLite](https://sqlite.org/) for storage.
> *(Reader clicks expecting schema details — finds a generic product page instead.)*

(Note that in the above example, the SQLite link is the SQLite home page, which is likely not pertinent.)

**Do:**

> See `[database schema](url)` for the full table structure.

### UI Language

Match UI element names exactly: wording, casing, and spacing (even if a label seems oddly worded).

**Don't:**

> Click the generator button.
> Select the save option.

**Do:**

> Click **Generate a Key**.
> Click **Save Changes**.

Someone will go looking for a button labeled "generator." They will not find it. They will be frustrated.

Consistency between documentation and interface builds confidence. Words are part of the interface.

:::{.tip}
This can be tricky as UI changes; we don't yet have a policy in place for how to handle this. We welcome comments and suggestions.
:::

### Clean system discipline

Your machine has things new users don't: cached credentials, installed tools, environment variables, existing configuration. When writing or updating documentation:

**Don't:**

> Write steps from memory on your development machine, assuming what works there will work everywhere.

**Do:**

> - Start on a clean system — a fresh VM or new user account
> - Take notes in real time as you work through the steps
> - Document every warning, prompt, or unexpected output the system shows

Also think in combinations: WSL vs native Linux, with and without existing keys. You don't need to test every matrix square — but you need to know which ones diverge.

### Never type code — always copy-paste

Always copy commands and code from a terminal where you just ran them successfully. Never retype from memory.

**Don't:**

> Retype a command from memory into the documentation.
> Retype code into a code-block from memory

**Do:**

> Paste commands directly from the shell or IDE.
> Paste code that has been successfully validated with nix-instantiate or nix-build

Replace sensitive values with placeholders: `<YOUR-KEY>`, `<YOUR-HOST>`, `<YOUR-TOKEN>`.

Typed-from-memory commands introduce subtle errors. Even the most experienced software developers have occasional typos.
