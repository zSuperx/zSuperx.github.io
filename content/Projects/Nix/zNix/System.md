---
title: NixOS Configuration
---

I have run through my fair share of flake libaries over the past few months
(`flake-utils`, `flake-parts`, `unify`, `import-tree`), but I'm now proud to say that with the
exception of `base16.nix`, the entire flake structure is dependency-less!

That is to say, any utility function used in this flake (again, with the
exception of `mkSchemeAttrs` from `base16.nix`) can be found within this flake
itself. It's all vanilla!

### Modules

This flake exposes a **lot** of `nixosModules`. I follow a simple preference:
all modules should be named and unreliant on their place in the file system.
What does this mean?

Unlike a normal `nixosModule`, which takes the form...

```nix
{ pkgs, ... }: {
  # NixOS options go here
}
```

... all imported `.nix` files will instead have the form:

```nix
{
  module-name = 
  { pkgs, ... }: {
    # NixOS options go here
  };
}
```

This form allows me to recursively import all files from a set of root
directories, and every file will be a named NixOS module! 

*(And now because I have nothing better to do, I will very quickly rant about my
preferences with this as opposed to path-based modules (`imports = [
./modules/something ]`).)*

In path-based modules, a module must be imported by explicitly providing its
path. Unlike my approach, path-based imports introduce a strict coupling
between two (or more) files, namely the import*er* and the import*ed*. But what
happens if you decide to change the name or location of the imported module? In
such instances, you must track down **all** instances of said file being
imported and change it. 

Additionally, path-based imports impose potentially unwanted naming conventions
to both your files and code. For example, suppose your tree looks like this...

```
dev/
├── foo
│   ├── default.nix
│   └── fighters.nix
└── bar
    ├── baz
    │   └── bruh.nix
    └── lol.nix
```

What do you do if `dev/bar/baz/bruh.nix` depends on options set in
`dev/foo/fighters.nix`? Does `imports = [ ../../foo/fighters.nix ]` really look
like the best solution?

Additionally, what should you be importing? `dev/bar/baz/bruh.nix`? or just `dev/foo` (due
to the presence of `default.nix`)?

Oh, and if your answer was "restructure the repo to not be this horrible"...
well, now you have to refactor them ALL due to the path coupling!

However, all of these issues simply vanish when using name-based imports, as it
simply becomes `imports = [ self.nixosModules.fighters ]`. And because named
modules are simply attribute sets, you can even...

1. have multiple named modules defined in a single file
```nix
{
  module-1 = { pkgs, ... }: {
    # ...
  };

  module-2 = { pkgs, ... }: {
    # ...
  };
}
```

2. conversely, have one named module be defined across *multiple* files
```nix
# file1.nix
{
  module-1 = {
    foo = "bar";
  };
}
```
```nix
# file2.nix
{
  module-1 = {
    foo2 = "bar2";
  };
}
```

3. my favorite, freely prefix modules by using Nix's attribute sets
```nix
{
  profiles.module-1 = { pkgs, ... }: {
    # ...
  };

  stupid.module-2 = { pkgs, ... }: {
    # ...
  };
}
```

See the next section to see how simple it is to import such named modules.

The two exceptions I make to the named-module rule are:

1. `hardware-configuration.nix` - This file should be locked in place and
   imported once, and preferably through `lib.nixosSystem`'s `modules` argument
   directly

2. Helper `.nix` files that a module file imports, where the two are placed
   next to each other in the file system to signify their relevance to each
   other. In such cases, a strict coupling is fine because the 2 files will
   only ever be moved as a set. (For an example, check out my `niri` settings
   configuration).

*(Hint: my recursive import function ignores all paths containing a component
prefixed with `_`, which is what makes these exceptions possible)*

### Profiles

Profiles have one semantic purpose: group regular modules together into a
collection that can all be  imported at once. Syntactically, they are actually
no different than modules, as a typical profile looks like:

```nix
{
  profiles.name =
  { self, ... }:
  {
    imports = with self.nixosModules; [
      module1
      module2
      module3
      module4
    ];
  };
}
```

This allows for modules to be as granular as they want while still being able
to connect together like pieces of a puzzle. For example, both `niri` and
`hyprland` rely on `wayland-utils`. Thus, it makes sense to define a `niri`
profile that imports the `niri` and `wayland-utils` modules. Similarily, a
`hyprland` profile exists to import `hyprland`, `hyprutils`, and
`wayland-utils`.

### Hosts

Finally, hosts are system configurations that consume modules and profiles. A
helper function (`self.lib.mkSystem`) exists to call `nixpkgs.lib.nixosSystem`
and import prerequisite modules (namely `mkAliasOptionModule [ "hm" ] [
"home-manager" "users" username ]`.

```nix
# hosts/gzero/default.nix
{
  self,
  userInfo,
  ...
}:
self.lib.mkSystem {
  inherit (userInfo) username;
  hostname = "gzero";
  system = "x86_64-linux";
  insanelySpecialArgs = userInfo;
  modules = with self.nixosModules; [
    profiles.basic
    profiles.dev
    profiles.hyprland
    profiles.gaming
    profiles.niri

    wayland-utils
    gBar
    gnome

    ./hardware-configuration.nix
  ];
}
```

As you can see, a host can import profiles, modules, files, or even flake
exposed modules (remember, they're all `nixosModules` at the end of the day!)
