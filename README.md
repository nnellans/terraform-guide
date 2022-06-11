Warning: This is not a very beginner-friendly guide.  Think of this more like an advanced cheat sheet, of sorts.  I went through the HashiCorp documentation as well as various books and captured any notes that I felt were relevant or important.  Then, I organized them into the README file you see here.  Some of it is still a work in progress, and I will update this over time.

If you are new to Terraform, then I would suggest going through the HashiCorp Docs or doing a couple HashiCorp Learn courses first.

# Terraform Files and Folders

### Configuration Files
- Files that contain Terraform code are called "configuration files"
- Configuration Files can in the typical, native form which uses a `.tf` file extension, or they can be in the alternate JSON form which uses a `.tf.json` file extension.
- This guide will be focused strictly on the native form using the `.tf` file extension.

### Root Module
- When you run terraform commands such as `plan` or `apply` you run it against a directory.
- This directory could contain just a single Configuration File.
- This directory could also contain multiple Configuration Files.
- Separating your Terraform code into multiple Configuration Files is totally optional and for you to decide.  Using multiple Configuration Files can make it easier for code readers and code maintainers.
- Terraform will automatically evaluate ALL Configuration Files that it finds in the top level of a directory.
- This top-level directory is commonly referred to as the "Root" Module.

### Typical Root Module File Structure
- File: `main.tf`
  - Contains all of your `resource` blocks, `module` blocks, and `data` (data source) blocks
- File: `outputs.tf`
  - Contains all of your `output` blocks
- File: `variables.tf`
  - Contains all of your `variable` blocks
- File: `versions.tf`
  - Contains your top-level `terraform` block as well as `provider` configuration blocks
  - This one is fairly new and not always found.  If it does not exist, then the information is typically found at the top of `main.tf` instead.
  - This one can also sometimes be found using the name `terraform.tf`

# Terraform State

## State Files
- State Files use a custom JSON format
- You should NEVER manually edit State Files
  - Instead, use commands like `terraform import` and `terraform state` to modify the state
- You should NEVER store your State Files in Version Control Systems like Git:
  - State Files often include passwords and sensitive information, and State Files are stored in plain text!  Therefore, it would be a bad idea to checkin a plain text file that includes passwords.
- Make sure your State Files are stored in a secure location and accessible only by users or accounts who require access

## Local Backend
- This is simply a file placed into the current directory, named `terraform.tfstate`
- Problems:
  - The state file is local to your computer, and can not be shared by other teammates
  - You are restricted to using only 1 local state file
- You can start with a Local Backend, and later you can add a Remote Backend to your code. Terraform will recognize the local State File and prompt you to copy it to the new Remote Backend

## Remote Backend
- A Remote Backend stores your State Files in remote shared storage (like Azure Storage Accounts, AWS S3 Buckets, etc.)
- Most Remote Backends support:
  - File locking, so only 1 person can run a `terraform apply` command at a time
  - Encryption at rest
  - Encryption in transit
- Configuring a Remote Backend is done in the root `terraform` block:

  ```terraform
  terraform {
    backend "azurerm" {
      key1 = value1
      key2 = value2
    }
  }
  ```

  The keys & values mentioned above are specific to the type of Remote Backend (in this case `azurerm`).  They specify:
  - How to find the storage (name, resource group, etc.)
  - How to authenticate to the storage (service principal, access key, etc.)
- Remote Backends can NOT use terraform variables or references
  - Terraform sets the Remote Backend as the very first step, even before it processes variables
  - You do not want to put sensitive values directly in this block, so instead you could use something like partial configuration.  This is where the backend block is missing the sensitive key/value pairs and instead you provide them via switches to terraform.exe:
    - `terraform.exe -backend-config="key=value" -backend-config="key=value"`
    - `terraform.exe -backend-config=backend.hcl`
      - Where backend.hcl is a file which contains only the key/value pairs that are needed
      - Do NOT check this file into version control if it contains sensitive values
    - Or, you could set special environment variables that the Remote Backend will automatically read from.  Each Remote Backend supports its own special environment variables.  Check the docs for your Remote Backend of choice.

## Terraform Workspaces
- You may want to consider these as 'local' Workspaces, as they are different from Terraform Cloud Workspaces
- If you create Workspaces, they each get their own state file.  However, all Workspaces still share the same Backend
- They are placed in a new subfolder called `env:` and each workspace gets its own subfolder under that:
  - `<backend>\env:\workspace1\terraform.tfstate`
  - `<backend>\env:\workspace2\terraform.tfstate`
- Switching workspaces is equivalent to changing the path where your state file is stored
- These are confusing. If possible, stay away from these

# Syntax

## Heredoc / multiline strings

```terraform
user_data = <<-EOF
            indented multi-line
            strings will go here
            EOF
    
user_data = <<EOF
non-indented multi-line
strings will go here
EOF
```

- `EOF` can be replaced with any word you choose
- If you use `<<` then the string will include any whitespace, if you use `<<-` then the string can be indented however you like to maintain readability.  Terraform will remove any whitespace in the front automatically

## Comments
- `#` begins a single-line comment, this is the default comment style
- `//` also begins a single-line comment
- `/*` and `*/` are start & end delimiters for multi-line comments

# Input Variables

## Defining a variable
- Typically, this is done in a separate `variables.tf` file

  ```terraform
  variable "Name" {
    description = "put a good description here"
    type        = string,number,bool,list,map,set,object,tuple,any
    default     = set a default value here
  }
  ```

- All three parameters are optional
- If `type` is omitted, then it is assumed to be `any`
- `type` can be a combination of different options:  `list(number)`
- How to set the value of the variable:
  - If not set by any other method, then terraform will interactively prompt you for a value when you run `terraform apply`
  - You can set a `default` value inside the variable definition.  Careful, as this is clear text
  - You can pass a value with the `-var` switch:

    ```bash
    terraform plan -var "name=value"
    ```

  - Setting environment variables with the name of `TF_VAR_<varName>`
    - Linux:

      ```bash
      export TF_VAR_varName=value
      ```

  - Using a file with a `.tfvars` extension that lists variable names and their values
    - Option 1: Terraform will automatically load your file if it is placed in your config directory and it is named:  `terraform.tfvars` or `*.auto.tfvars`
    - Option 2: Pass your tfvars file with the `-var-file` switch:

      ```bash
      terraform plan -var-file=somefile.tfvars
      ```

## Using a variable
- `var.name`
- Using a variable inside of a string (interpolation):
  
  ```terraform
  "some string ${var.name} some more string"
  ```

## List/Array Variables
- Examples:
  - `type = list(string)`
  - `type = list(number)`
  - `type = list`
    - This is shorthand for `list(any)`.  But, the list values must still all be the same type (string, number, etc.)
    - This shorthand is not recommended any more
- Setting the value of a list variable:

  ```terraform
  listName = [ "first", "second", "third" ]
  ```

- Using a specific value from the list:  `var.listName[3]`
- Terraform lists are zero-based, so the the first entry is `var.listName[0]`
- Some example List Functions:
  - Find the number of items inside a list:  `length(var.listName)`

## Tuple Variables
- This is the 'structural' version of a list variable.
- It allows you to define a schema within square brackets, which can use different variable types inside the tuple, instead of being restricted to the same variable type when using a list.
  - `type = tuple( [schema] )`
  - `type = tuple( [ string, number, bool ] )`

## Map Variables
- Examples:
  - `type = map(string)`
    - This defines a map where all the values are strings.
  - `type = map(number)`
    - This defines a map where all the values are numbers.
  - `type = map`
    - This is shorthand for `map(any)`.  But, the map values must all be the same type (string, number, etc.)
    - This shorthand is not recommended any more.
- Setting the map variable, two options:
  - Put each pair on a new line.

        mapName = {
          key1 = value1
          key2 = value2
        }

  - For a single line, you must use commas to separate key/value pairs.	

        mapName = { key1 = value1, key2 = value2 }

- Keys are always strings.  Quotes may be omitted on the keys (unless the key starts with a number, in which case quotes are required)
- You can use either equal signs `key1 = value1` or colons `key1 : value1`.  However, `terraform fmt` ignores colons.
- Using a specific value from the map, two options:
  - `var.mapName["1key"]`
    - You must use this if the key begins with a number
  - `var.mapName.key1`
    - You can also use this option (as long as your key does not start with a number)
- Map Functions:
  - Return just the values from a map:  `values(var.mapName)`

## Object Variables
- This is the 'structural' version of a map variable.
- It allows you to define a schema within curly brackets, which can use different variable types inside the object, instead of being restricted to the same variable type when using a map.
  - `type = object( {schema} )`
  - `type = object( { name = string, age = number } )`

# Output Variables

- These are used when you want to output values in one terraform configuration, and consume them from a separate terraform configuration.
- Defining an output variable:

      output "Name" {
        value       = any terraform expression that you wish to output
        description = "put a good description here"
        sensitive   = true
      }

  - Typically, this is done in a separate `outputs.tf` file
  - `value` is the only required parameter.
  - Setting the `sensitive=true` parameter means that Terraform will not display the output’s value at the end of a `terraform apply`
- Using an Output Variable
  - You can use a Remote State Data Source (see below) to read Output Variables.

# Local Values

- Normal Input Variables do not allow expressions or interpolations in their values, but that is totally acceptable with Local Values.
- Defining Local Values:

      locals {
        first  = "some text"
        second = "some text with a ${var.otherVariable} thrown in"
        third  = [ "list", "example" ]
      }

- Using Local Values:
  - `local.first`
  - `local.third[0]`

# Data Sources

- Data Sources are Read-Only!!!
- Data Sources fetch up-to-date information from your providers (Azure, AWS, etc.) each time you run terraform.
- Each provider has their own list of supported Data Sources.
- Defining a data source:

      data "azurerm_some_datasource" "name" {
        one or more          = arguments
        that are specific to = this data source
      }

  - The argument(s) that you specify can be thought of like search filters to limit what data is returned.
- Using a data source: `data.azurerm_some_datasource.<name>.<attribute>`
  - Where `attribute` is specific to the resource that is being fetched by the data source

## Remote State Data Source
- When you want to pull info from a foreign terraform state file.
- That foreign terraform state must have some `outputs` already configured, because that is the information you are pulling from.
- Defining a Remote State data source:

      data "terraform_remote_state" "name" {
        backend = "azurerm"
        config = {
          key1 = value1
          key2 = value2
        }
      }

  - In the `config` block you specify the storage and state file to connect to, as well as how to authenticate to that storage.  You can use the same parameters you used for the remote backend settings.
  - Partial config is not supported for Remote State Data Sources.
- Using a Remote State data source: `data.teraform_remote_state.<dataSourceName>.outputs.<outputName>`

## External Data Source
- Provides an interface between Terraform and an external program
- Example:

      data "external" "example" {
        program = ["python", "${path.module}/example-data-source.py"]

        query = {
        # arbitrary map from strings to strings, passed
        # to the external program as the data query.
          id = "abc123"
        }
      }

- Requirements:
  - The `program` must read all of the data passed to it on `stdin`
    - The `program` must parse all of the data passed to it as a JSON object
    - The JSON object must contain the contents of the `query`
  - The `program` must produce a valid JSON object on `stdout`
    - The JSON object must have all of its values as strings
  - On successful completion
    - The `program` must exit with a status of zero
  - If there's an error
    - The `program` must exit with a non-zero status
    - It must print a human-readable error message (ideally a single line) to `stderr`
    - `stdout` is ignored for an error
- Terraform will re-run `program` each time that state is refreshed.
  - `program` is of type list(string)
    - First element is the program to run, and subsequent elements are optional commandline arguments.
    - Terraform does not execute the program through a shell, so it is not necessary to escape shell metacharacters nor add quotes around arguments containing spaces.
  - `query` is of type map(string)
    - Optional
    - These values are passed to the program as query arguments.
- How to reference the data created from the external data source:
  - `data.external.<name>.result.<someAttribute>`

## Template File Data Source
- Defining a Template File Data Source:

      data "template_file" "name" {
        template = file("somefile.txt")

        vars = {
          key1 = value1
          key2 = value2
        }
      }

  - The file you provide is processed as a string.  Any time a matching variable key is found in the string, it is replaced with the variable value specified.
- The string must be formatted like this:
  `in this string ${key1} will be replaced and ${key2} will also be replaced`
- `template` could also be just a simple string value or string variable that you want to modify.
- Using the rendered output from a Template File Data Source:
  - `data.template_file.<dataSourceName>.rendered`

# Loops

## count Parameter
- Every terraform resource has a parameter you can use called `count`
- It defines how many copies of that resource to create
- Example:

      resource "someResource" "someName" {
        count = 5
      }

- `count` must reference hardcoded values, variables, data sources, and lists
  - It can NOT reference a value that needs to be computed
- When you specify the `count` parameter on a resource, then you can use a new variable inside that resource:  `count.index`
  - `count.index` represents the number of the loop that you’re currently on.
  - For example, say you had a resource with `count = 3`
    - The first resource will set `count.index = 0`
    - The second resource will set `count.index = 1`
    - The third resource will set `count.index = 2`
  - You can use this on resource parameters that are required to be unique:  `name = "resource-group-${count.index}"`
  - You can get creative with this by building a separate List variable that contains the values you would like to use inside of the resource that is using `count`

        var.listOfNames = ["peter", "paul", "mary"]
        resource "someResource" "someName" {
          count = length(var.listOfNames)
          name  = var.listOfNames[count.index]
        }

- **When you use count on a resource, the resource now becomes an List**
  - To reference a single instance of the resource created by `count`:  `azurerm_storage.someName[2].id`
  - To reference all instances of the resource created by `count`:  `azurerm_storage.someName[*].id`
    - This is called a "splat expression"

### Drawback 1:  You can not use the count parameter with inline blocks.
- For example, take this resource:

      resource "someResource" "someName" {
        key1 = value1
        key2 = value2

        inline-block {
          keyA = valueA
          keyB = valueB
        }
      }

  - If you needed to create multiple inline-blocks, then you may be tempted to just put the `count` parameter inside the inline-block.  However, that is NOT supported.

### Drawback 2:  Be careful when you remove a resource instance from the middle of the list.
- For example, say you used `count = 3` to create some users:
  - `user[0] = neo`
  - `user[1] = morpheus`
  - `user[2] = trinity`
- Now, say you deleted the middle resource `morpheus`.  Every resource in the list after that will shift backwards in terms of index count, so you will be left with:
  - `user[0] = neo`
  - `user[1] = trinity`
  - This is a problem because terraform will need to delete the original `trinity[2]` and then create a new `trinity[1]`
- **If you remove an item from the middle of the list, terraform will delete every resource after that item, and then it will recreate those resources again from scratch with new index values.**

## for_each Parameter
- Inside of a resource you can use a parameter called `for_each`

      resource "someResource" "someName" {
        for_each = var.Set or var.Map
      }

- So, if your var.Set/var.Map has 5 entries, then you'll get 5 different copies of that Resource
- List variables are NOT supported in Resource Block `for_each`.  You must convert a List to a Set variable:  `for_each = toset(var.List)`
- `for_each` must reference hardcoded values, variables, data sources, and lists.
  - It can NOT reference a value that needs to be computed
- When you specify the `for_each` parameter on a resource, then you can use new variables inside that resource:  `each.key` and `each.value`
  - For a Set variable:
    - `each.key` and `each.value` are both set to the current item in the Set
    - Typically, you would just use `each.value` here
  - For a Map variable:
    - `each.key` = the key of the current item in the Map
    - `each.value` = the value of the current item in the Map
- When you use `for_each` on a resource, the resource now becomes a Map
  - To reference a single instance of the resource created by `for_each`:  `azurerm_storage.someName[key].id`

### Benefit 1:  You can now delete an instance from the middle of the set/map without any trouble.
- Since the resource is now considered a Map, deleting from the middle will no longer affect items further down the chain.

### Benefit 2:  You can now use for_each inside of an inline block in a resource, by using a dynamic block

    resource "someResource" "someName" {
      key = value
    
      dynamic "<inlineBlockToDuplicate>" {
        for_each = var.List or var.Map

        content {
          key1 = <inlineBlockToDuplicate>.key
          key2 = <inlineBlockToDuplicate>.value
        }
      }
    }

- So, if your var.List/var.Map has 5 entries, then you'll get 5 different copies of that Inline Block
- List variables ARE supported in Inline Blocks `for_each`, but Set variables are NOT.
  - This is confusing:
  - Sets are allowed on resources but not on inline blocks.
  - Lists are allowed on inline blocks but non on resources.
  - Maps are allowed on both resources & inline blocks.
- When you specify the `for_each` parameter on an inline block, then you can use new variables inside that Inline Block:  `<inlineBlockToDuplicate>.key` and `<inlineBlockToDuplicate>.value`
  - For a List variable:
    - `<inlineBlockToDuplicate>.key` = the numeric index of the current item in the List
    - `<inlineBlockToDuplicate>.value` = the value of the current item in the List
  - For a Map variable:
    - `<inlineBlockToDuplicate>.key` = the key of the current item in the Map
    - `<inlineBlockToDuplicate>.value` = the value of the current item in the Map

# "for" Expressions

## [for] Expressions – return a Tuple

### Input a List, return a Tuple
- `newList = [for <item> in var.List : <output> <condition>]`
  - `<item>` is the local variable name to assign to each item in the list
  - `<output>` is what to put into the resultant List, it can be an expression that modifies the `<item>` in some way
  - `<condition>` is optional and you could use it to further refine what values go into the resultant List
- Example:
  - `newList = [for name in var.List : upper(name) if length(name) < 5]`
  - This looks at `var.List` and converts each entry to uppercase, returns only the names that are less than 5 characters, and stores the modified entries in `newList`

### Input a Map, return a Tuple
- `newList = [for <key>, <value> in var.Map : <output> <condition>]`
- The rest is the same as above
- Example: `newList = [for first, last in var.Map : “Hi I’m ${first}, and my last name is ${last}!”]`

## {for} Expressions – return an Object
- Notice that this uses curly brackets instead of square brackets
- Also notice the arrow sign `=>` separating `outputKey` & `outputValue`

### Input a List, return an Object
- `newMap = {for <item> in var.List : <outputKey> => <outputValue> <condition>}`
  - `<item>` is the local variable name to assign to each item in the list
  - `<outputKey>` and `<outputValue>` is what to put into the resultant Map, they can be expressions that modify the `<item>` in some way
  - `<condition>` is optional and you could use it to further refine what key/value pairs go into the resultant Map

### Input a Map, return an Object
- `newMap = {for <key>, <value> in var.Map : <outputKey> => <outputValue> <condition>}`
- The rest is the same as above

# String Directives

## for Loops
- **Work In Progress**
- This let’s you loop over a List variable or a Map variable

      <<EOF
      %{ for <item> in <collection> }
      do something to <item>
      %{ endfor }
      EOF

- Strip Markers ( ~ ) allow you strip out unwanted spaces and newlines

      %{~ for blahblah }
      %{~ endfor }
      %{ for blahblahblah ~}
      %{ endfor ~}

## Conditionals
- **Work In Progress**
- This let’s you run an if statement within a string

      %{ if someCondition }
      value if true
      %{ endif }

- You can also do an if/else statement

      %{ if some condition }
      value if true
      %{ else }
      value if false
      %{ endif }

# Modules

- A terraform Module is nothing more than a folder full of .tf files.
  - All the .tf files you have been writing in the root folder are considered the “root module”
  - The module’s folder should include the usual suspects:  `main.tf`, `variables.tf`, `outputs.tf`
    - `main.tf` = where you specify the resources that will be created
    - `variables.tf` = where you specify the variables that can be passed into the module when you call it
    - `outputs.tf` = where you specify what will be returned when the module is called
- Using a Child Module / Calling a Child Module:

      module "someName"  {
        source = “path/to/the/module/folder”

        key1 = value1
        key2 = value2
      }

  - The keys/values are your way of passing input parameters to the Child Module.
  - The Child Module defines what is accepted for input parameters via its own `variables.tf` file in its own folder
  - Tip: The `source` attribute could point to a git repo if you wanted.
    - That way you could use git tags to create “versions” of your module, and then you can reference specific versions of each module.
- Reference a value that is produced by a Module:
  - `module.<someName>.<outputName>`
  - Tip:  this could then be used in the root module’s outputs.tf
- Some provider Resources let you configure certain settings either using inline blocks or by using totally separate Resources.  For modules, it is preferential to use the separate Resources.
  - This way your module might configure 2 settings this way, and then you could add 3 more settings outside of the module if you wanted.
  - If the settings were done in the module using inline blocks, then there would be no way to add extra settings to that outside of the module.
- Be careful when using the file() function inside of a Child Module, as the path to the file can get tricky.  Here are some special system variables that can help with this:
  - `path.module`:  references the folder where the child module is located
  - `path.root`:  references the folder of the root module

# Lifecycle Settings

    resource "azurerm_some_resource" "someName" {
      key = value

      lifecycle {
        create_before_destroy = true
        prevent_destroy       = true
        ignore_changes        = [ attribute1, attribute2 ]
      }
    }

- Every terraform resource supports a Lifecycle block
- It can configure how that resource is created, updated, or deleted.
- `create_before_destroy`
  - By default, when terraform must replace a resource, it will first delete the old/existing one, and then it will create the new one after that.
  - If your old/existing resource is being referenced by other resources, then terraform will not be able to delete it.
  - The create_before_destroy option flip-flops this, so terraform will first create the new resource, update any references that are needed, and then delete the old/existing resource.
- `prevent_destroy`
  - The prevent_destroy option will cause Terraform to exit on any attempt to delete that resource.
- `ignore_changes`
  - This is a list of resource attributes that you want Terraform to ignore.  If the value of that attribute differs in real life vs. the Terraform code, then Terraform will just ignore it and not try to make any changes.

# Terraform Commands

## terraform apply
- work in progress

## terraform console
- Interactive, read-only console to try out built-in functions, query the state of your infrastructure, etc.

## terraform destroy
- Looks at the current folder, and deletes all resources
- There is no "undo" be very careful!

## terraform fmt
- work in progress

## terraform graph
- Looks at the current folder, and shows you the dependency graph for the resources
- It outputs into a graph description language called DOT
- You can use Graphviz or GraphvizOnline to convert into an image

## terraform import
- work in progress

## terraform init
- Downloads any providers that are found in your code, they are put here:  `<currentDirectory>\.terraform\`
- You must run `init` each time you change settings for your remote backend
- You must run `init` each time you reference a new Module, or change Module settings

## terraform output
- Looks at the current folder, and lists all of the Output Variables
- List a specific Output Variable only:  `terraform output <name>`
  - Tip:  this is great for scripts where you may need to grab an output variable from terraform and use it somewhere else.

## terraform plan
- work in progress

## terraform state
- work in progress

## terraform workspace
- To work with terraform workspaces

# .gitignore File

## .terraform
- Terraform’s scratch directory, is created inside each config folder where you run `terraform init` and includes the downloaded providers.

## *.tfstate
- Local state files, never check these into version control as they contain secrets in clear text

## *.tfstate.backup
- Backups of local state files

## backend.hcl
- The standard filename when you use partial configuration for Remote Backend.
- You only need to ignore this if you're storing **sensitive** keys/values in this file.
