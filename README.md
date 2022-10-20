Warning: This is an advanced guide.  It is not very beginner friendly and it assumes you already know the basics of Terraform.  Think of this like an advanced cheat sheet.  I went through the HashiCorp documentation, as well as various books, and captured any notes that I felt were relevant or important.  Then, I organized them into the README file you see here.

Terraform comes in a few different versions.  This guide covers Terraform "Open Source" only.  It does not cover anything for Terraform "Cloud" or Terraform "Enterprise".

It's important to know that this is a live document.  Some of the sections are still a work in progress.  I will be continually updating it over time.

If you are new to Terraform, then I would suggest first going through the [HashiCorp Docs](https://www.terraform.io/docs) or doing a couple [HashiCorp Learn](https://learn.hashicorp.com/) courses.

---

# Table of Contents

Part 1 - Terraform Files, Folder Structure, and Blocks
- [Configuration Files](README.md#configuration-files)
- [Root Module](README.md#root-module)
- [Folder Structure](README.md#typical-root-module-folder-structure)
- [terraform Block](README.md#terraform-block)
- [provider Blocks](README.md#provider-configuration-blocks)
- [terraform init](README.md#terraform-init)

Part 2 - Terraform State
- [State Files](README.md#state-files)
- [Local Backend](README.md#local-backend)
- [Remote Backend](README.md#remote-backend)
- [Terraform Workspaces](README.md#terraform-workspaces)

Part 3 - Terraform Code
- [Input Variables](README.md#input-variables-aka-variables)
- [Local Values](README.md#local-values-aka-locals)
- [Data Sources](README.md#data-sources)
- [Resources](README.md#resources)
- [Child Modules](README.md#child-modules-aka-modules)
- [Output Variables](README.md#output-variables-aka-outputs)

Part 4 - Everything Else
- [Syntax Notes](README.md#syntax-notes)
- [Loops (count and for_each)](README.md#loops)
- [For Expressions](README.md#for-expressions)
- [String Directives](README.md#string-directives)
- [Lifecycle Settings](README.md#lifecycle-settings)
- [Terraform CLI Commands](README.md#terraform-cli-commands)
- [.gitignore File](README.md#gitignore-file)

---

## Terraform Files, Folder Structure, and Common Code Blocks

### Configuration Files
- Files that contain Terraform code are officially called *configuration files*
- Configuration Files can be written in two different formats:
  - native format which uses the `.tf` file extension
  - alternate JSON format which uses the `.tf.json` file extension
- This guide will only focus on the native format

### Root Module
- When you run Terraform commands such as `terraform plan` or `terraform apply` you run it against a directory of Configuration Files.  This directory could contain one Configuration File, or it could contain many
- Separating your Terraform code into multiple Configuration Files is totally optional and for you to decide.  Using multiple Configuration Files can make it easier for readers and maintainers of your code
- Terraform will automatically evaluate ALL Configuration Files found in the **top level** of the directory you run it against
- This top-level directory is commonly referred to as the *Root Module*

### Typical Root Module Folder Structure
- `main.tf`
  - Contains all of your `locals` blocks, `resource` blocks, `module` blocks, `data` blocks
- `outputs.tf`
  - Contains all of your `output` blocks
- `variables.tf`
  - Contains all of your `variable` blocks
- `versions.tf`, `terraform.tf`, `providers.tf`
  - Recently, it has been common to put the `terraform` configuration block and all of your `provider` configuration blocks into separate Configuration Files
  - Some of the common filenames that I've seen used for this are `versions.tf`, `terraform.tf`, or `providers.tf`
  - You may not always find these files.  If they don't exist, then these blocks are typically found in `main.tf` instead
- `dependencies.tf`
  - Another fairly recent practice is to put all of your `data` blocks (data sources) into this separate Configuration File
  - Same as above, you may not always find this file, and if not, the `data` blocks are typically found in `main.tf` instead

### terraform block
```terraform
terraform {

  required_version = "=1.2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.7.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "=4.18.0"
      configuration_aliases = [ aws.second ]
    }
  }

  backend "azurerm" {
    resource_group_name  = "value"
    storage_account_name = "value"
  }

}
```
- The `terraform` block supports hard-coded values only
- `required_version` is used to specify which version(s) of Terraform are supported by this Root Module
  - You can specify an exact version, a min version, a max version, or even a range of versions.  See the [Version Constraints](https://www.terraform.io/language/expressions/version-constraints) documentation for more info
- `required_providers` declares which providers are used by this Root Module (plus any Child Modules too), so that Terraform can install and use these Providers.  This is how you specify which version(s) of each Provider are supported by this Root Module
  - The `configuration_aliases` argument is used when you have multiple copies of the same Provider, you must list all of the extra aliases here
- `backend` is used to configure which Backend the Terraform CLI will use
- The `terraform` block has a few other uses, but they will not be covered here.  Read the [Terraform Settings](https://www.terraform.io/language/settings) docs for more info
- The `terraform` block should exist in both the Root Module as well as all Child Modules
  - However, in Child Modules you should specify *minimum* versions only.  This goes for both the Terraform version and Provider versions.  Let the Root Module specify the *maximum* versions for both.

### provider Configuration Blocks
```terraform
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "second"
  region = "us-west-2"
}

provider "azurerm" {
  # version = "1.0"   # DEPRECATED! DO NOT USE!
  features {}
}

provider "google" {
  project = "acme-app"
  region  = "us-central1"
}
```
- Each Provider has its own unique settings.  This may include things such as the credentials used to authenticate to the vendor's API, which region to use, which subscription to use, etc.
  - Do not put sensitive credentials in the `provider` block.  Passwords stored directly in code are **bad**!
  - Some Providers support alternate ways to provide these values, such as using environment variables.  It is recommended to use these alternate methods
  - Check out your Provider's documentation for more information
- You may still see code that uses the `version` argument inside of a `provider` block.  Do NOT use this, it's deprecated.  Instead, you should specify the supported Provider versions in the `terraform` block (see above)
- You can declare multiple `provider` blocks for a single Provider, with each block using a different configuration.  See the two `aws` blocks in the example code above
  - The first instance you define is considered the "*default* Provider and does not need to use the `alias` argument
  - Any other instances you define must have a unique `alias` argument that will be used to reference this instance of the Provider
  - Don't forget to also include the extra aliases in the `terraform / required_providers` block (see above)
- `provider` configuration blocks go in the Root Module ONLY, they should not exist in Child Modules

### terraform init
You must run `terraform init` at least once before you can run any `plan` or `apply` commands.  The `terraform init` command is a powerful command that has 3 different purposes:
- Configures your Providers
  - It looks at your Configuration Files, figures out which Providers your code uses, and then automatically downloads those Providers into the `.terraform` folder
  - It will automatically create a lock file named `.terraform.lock.hcl`
    - The lock file stores the exact versions of the Providers that were downloaded by `init`
    - You should store this file in version control along with your code.  This way everyone will use the same lock file and as a result everyone will download the same Provider versions
    - How do you upgrade to a new Provider version?  First, upgrade the Provider version in the `terraform.required_providers` block and then run `terraform init -upgrade`.  This will download the new Provider and it will automatically update the `.terraform.lock.hcl` file as well
  - Any time you add a new Provider to your code you will need to run `terraform init` again in order to download that Provider
- Initializes your chosen Backend
  - Any time you change to a different Backend you will need to run `terraform init` again in order to initialize the new Backend
- Configures your Modules
  - Any time you add a Module to your Configuration Files, or you change the source of an existing Module, you will need to run `terraform init` again

---

# Terraform State

### State Files
- State Files use a custom JSON format
- You should NEVER manually edit State Files.  Instead, use commands like `terraform import` and `terraform state` to modify the state
- You should NEVER store your State Files in Version Control Systems like Git:
  - State Files are stored in plain text, and they often include passwords and other sensitive information
- Make sure your State Files are stored in a secure location and accessible only by users or accounts who require access

### Local Backend
- This is the default backend that Terraform will use unless you specify a different backend
- This will be created as a file named `terraform.tfstate` in the Root Module
- Problems with a Local Backend:
  - The State File is local to your computer and can not be shared by other teammates
  - You can only use 1 local State File
    - (Workspaces are an exception, but they are not recommended)
- You can start with a Local Backend, and later you can change your code to use a Remote Backend. Terraform will recognize the local State File and prompt you to copy it to the new Remote Backend

### Remote Backend
- You can only configure 1 Remote Backend per Root Module
- Configuring a Remote Backend is done in the `backend` block inside the `terraform` block:
  ```terraform
  terraform {
    backend "azurerm" {
      key1 = value1
      key2 = value2
      key3 = value3
    }
  }
  ```
- Remote Backends require configuration parameters, which specify:
  - How to find the storage (name, resource group, etc.)
  - How to authenticate to the storage (service principal, access key, etc.)
- Read your Remote Backend's documentation for for more info
- `backend` blocks can NOT use Terraform variables or references, they must use hard-coded values
  - This is because Terraform sets the Remote Backend as its very first step, even before it processes variables
- Do NOT put sensitive values directly in the `backend` block.  Passwords in code are bad!
- You can remove some or all of the key/value pairs from the `backend` block and provide them in other ways:
  - Option 1 is individual key/value pairs:  `terraform.exe -backend-config="key=value" -backend-config="key=value"`
  - Option 2 is to use a separate file:  `terraform.exe -backend-config=backend.hcl`
    - Where `backend.hcl` is a file which contains only the key/value pairs that are needed by the backend
    - If this file contains sensitive values, then do NOT check it into version control
  - Option 3 is using environment variables supported by your Backend.  Each Backend supports its own special environment variables.  Check your Backend's documentation for more information
    - This is the preferred option, as credentials are kept out of your code

### Terraform Workspaces
- Note: These are different from Terraform "Cloud" Workspaces
- If you create Workspaces, they each get their own State File.  However, all Workspaces will still share the same Backend
- State Files for Workspaces are placed in a new subfolder called `env:` and each Workspace gets its own subfolder under that:
  - `<backend>\env:\workspace1\terraform.tfstate`
  - `<backend>\env:\workspace2\terraform.tfstate`
- Switching Workspaces is equivalent to changing the path where your State File is stored
- In general, these are confusing.  It can be easy to mix up Workspaces and forget which one you are currently working on
- If possible, stay away from using these!

---

# Input Variables (aka Variables)

```terraform
# defining a variable
# remember, this is typically done inside a variables.tf file
variable "exampleVarName" {
  description = "put a good description here"
  type        = string | number | bool | list | tuple | set | map | object | any
  default     = set a default value here
  sensitive   = true   # supported in Terraform 0.14.0 and later
  nullable    = false  # supported in Terraform 1.1.0 and later
  
  # supported in Terraform 0.13.0 and later
  # you can have multiple validation blocks
  validation {
    # some condition that must resolve to either true or false
    # the condition can reference this variable and this variable only
    condition     = var.exampleVarName > 10
    # an error message to show if the condition is false
    error_message = "your value needs to be greater than 10"
  }
}

# use a variable by prefixing the variable's name with var.
var.exampleVarName
```
- When defining a Variable, all parameters are optional
  - If `type` is omitted, then the default is `any`
- `type` can be a combination of different options:  `list(number)`

### How to set values for your Variables:
1. You can set a `default` value inside the Variable definition
2. Set an environment variable with the name of `TF_VAR_<varName>` and the value that you want to use
   - Linux: `export TF_VAR_varName=value`
   - PowerShell: `$env:TF_VAR_varName = 'value'`
3. Use a file with a `.tfvars` extension that lists Variable names and their values
   - Option 1: Terraform will automatically load your file if it is placed in your Root Module and it is named `terraform.tfvars` or `*.auto.tfvars`
   - Option 2: Pass your tfvars file with the `-var-file` switch: `terraform.exe plan -var-file=somefile.tfvars`
4. Pass a value with the `-var` switch: `terraform plan -var "name=value"`
5. If not set by any other method, then Terraform will interactively prompt you for a value at runtime

Values are loaded in the following order, with the later options taking precedence over earlier ones:
1. Environment Variables
2. `terraform.tfvars` files
3. `*.auto.tfvars` files
4. `-var` and `-var-file` options, in the order they are given on the commandline

# Variable Types

### Strings
Represented by characters surrounded by double-quotes: `"this is a string"`

Heredoc / Multi-line Strings
```terraform
user_data = <<-EOT
            indented multi-line
            strings will go here
            EOT
    
user_data = <<EOT
non-indented multi-line
strings will go here
EOT
```
- `EOT` can be replaced with any word you choose
- If you use `<<` then the string will include any whitespace, so don't indent your lines unless you want those indents in your string
- If you use `<<-` then Terraform will remove any leading spaces automatically, so the string can be indented however you like to maintain readability

### List Variables
Lists are represented by a pair of square brackets `[ ]` containing a comma-separated sequence of values.  For Lists, all the values must be of the same Type
- `type = list(string)` This defines a List of all Strings
- `type = list(number)` This defines a List of all Numbers
- `type = list`
  - This shorthand is not recommended any more.  Instead, use `list(any)`
  - When using `list` or `list(any)` the List values must still all be the same Type (string, number, etc.)
- Setting the value of a List variable, two options:
  1. Put each value on its own line, separated by commas
     ```terraform
     listName = [
       "first",
       "second",
       "third"
     ]
     ```
  2. Put all values on a single line, also separated by commas
     ```terraform
     listName = [ "first", "second", "third" ]
     ```
- A comma after the last value is allowed, but not required
- Using a specific value from the List:  `var.listName[3]`
- Lists are zero-based, so the the first entry is always index 0:  `var.listName[0]`
- Some example List Functions:
  - Find the number of items inside a list:  `length(var.listName)`

### Tuple Variables
- This is the *structural* version of the List type
- You are allowed to use different variable Types inside the Tuple
- It requires you to define a schema within Square Brackets:
  - `type = tuple( [schema] )`
  - Example: `type = tuple( [ string, number, bool ] )`

### Map Variables
Maps are represented by a pair of curly braces `{ }` containing a series of key/value pairs
- Keys are always strings
- Values must always be of the same Type
- `type = map(string)` This defines a Map where all the values are Strings
  ```terraform
  mapName = {
    Key = "Value"
    Key = "Value"
  }
  ```
- `type = map(number)` This defines a Map where all the values are Numbers
  ```terraform
  mapName = {
    Key = 500
    Key = 32
  }
  ```
- `type = map(list(string))` This defines a Map where all the values are Lists of Strings
  ```terraform
  mapName = {
    Key = [ "value", "value" ]
    Key = [ "value", "value" ]
  }
  ```
- `type = map`
  - This shorthand is not recommended any more.  Instead, use `map(any)`
  - When using `map` or `map(any)` the Map values must still all be the same Type (string, number, etc.)
- Quotes may be omitted on the Keys (unless the key starts with a number, in which case quotes are required)
- Setting the value of a Map variable, two options:
  1. Put each pair on its own line, separated by line breaks:
     ```terraform
     mapName = {
       key1 = value1
       key2 = value2
     }
     ```
  2. For a single line, you must use commas to separate each pair:
     ```terraform
     mapName = { key1 = value1, key2 = value2 }
     ```
- You can use either equal signs `key1 = value1` or colons `key1: value1`
  - However, `terraform fmt` does NOT work on the colon style
- Using a specific value from the Map, two options:
  1. `var.mapName.key1`
  2. `var.mapName["1key"]`
     - You must use this if the Key begins with a number
- Some example Map Functions:
  - Return just the values from a Map:  `values(var.mapName)`

### Object Variables
- This is the 'structural' version of a Map variable
- You are allowed to use different variable Types for each Value of the Object
- It requires you to define a schema within Curly Brackets
  - `type = object( {schema} )`
  - Example: `type = object( { name = string, age = number } )`

# Local Values (aka Locals)
```terraform
# defining multiple locals
locals {
  first  = "some text"
  second = "some text with a ${var.otherVariable} thrown in"
  third  = [ "list", "example" ]
}

# use a local by prefixing the local's name with local.
local.second
```
- Instead of embedding complex expressions directly into resource properties, use Locals to contain the expressions
- This makes your Configuration Files easier to read and understand. It avoids cluttering your resource definitions with logic
- You can have a single `locals` block where you define multiple Locals, or you can split them up into multiple `locals` blocks

# Data Sources
```terraform
# defining a data source
data "azurerm_storage_account" "someSymbolicName" {
  name                = "name"
  resource_group_name = "rgName"
}

# use a data source
data.azurerm_storage_account.someSymbolicName.<attribute>

# Where `attribute` is specific to the resource that is being fetched by the data source
# In this case it could be id, location, account_kind, etc.
```
- Data Sources fetch up-to-date information from your Providers (Azure, AWS, etc.) each time you run Terraform
  - Each Provider has their own list of Data Sources that they support
- All Data Sources are Read-Only!
- When defining a Data Source, the argument(s) that you specify can be thought of like search filters to limit what data is returned

## Other types of Data Sources
<details><summary>Click to expand</summary>

### Remote State Data Source
- Use these when you want to pull info from a foreign Terraform State File
- That foreign Terraform State must have some `outputs` already configured, because that's the information you're pulling from

```terraform
# Defining a Remote State Data Source
data "terraform_remote_state" "symbolicName" {
  backend = "azurerm"
  config = {
    key1 = value1
    key2 = value2
  }
}

# Using a Remote State Data Source:
`data.teraform_remote_state.symbolicName.outputs.someOutputName`
```
- In the `config` block you specify the storage and state file to connect to, as well as how to authenticate to that storage.  You can use the same parameters you used for the Remote Backend settings
- Partial config is NOT supported for Remote State Data Sources

### External Data Source
- Provides an interface between Terraform and an external program
- Example:
  ```terraform
  data "external" "symbolicName" {
    program = ["python", "${path.module}/example-data-source.py"]

    query = {
      id = "abc123"
    }
  }
  ```
- The `program` must read all of the data passed to it on stdin
  - The `program` must parse all of the data that's passed to it as a JSON object
  - The JSON object must contain the contents of the `query`
- The `program` must produce a valid JSON object on stdout
  - The JSON object must have all of its values as Strings
- On successful completion the `program` must exit with a status of zero
- If there's an error
  - The `program` must exit with a non-zero status
  - It must print a human-readable error message (ideally a single line) to `stderr`
  - `stdout` is ignored for an error
- Terraform will re-run `program` each time that state is refreshed
- `program` is of Type list(string)
  - First element is the program to run, and subsequent elements are optional commandline arguments
  - Terraform does not execute the program through a shell, so it is not necessary to escape shell metacharacters nor add quotes around arguments containing spaces
- `query` is of Type map(string)
  - Optional
  - These values are passed to the program as query arguments
- How to reference the data created from the external data source:
  - `data.external.symbolicName.result.someAttribute`
</details>

# Resources
- Resources are the most important element in the Terraform language
- Each `resource` block describes one or more infrastructure objects, such as virtual networks, compute instances, or higher-level components such as DNS records
```terraform
# defining a resource from the azurerm provider
resource "azurerm_storage_account" "someSymbolicName" {
  name     = "someName"
  location = "someLocation
}
```
- In this example, the resource type is `azurerm_storage_account` and if we look at the beginning of the resource type we can tell that it comes from the `azurerm` Provider.
  - Each Provider supports its own set of resource types
  - Each Provider also defines the acceptable parameters to use for each resource type
  - Check your Provider's documentation to learn more about the supported resource types and their supported parameters
- Terraform also supports a number of *Meta-Arguments* that are available to use for each `resource` block, such as `depends_on`, `count`, `for_each`, `provider`, `lifecycle`, and `provisioner`
- This guide will go over the `count`, `for_each`, and `lifecycle` meta-arguments.  But, for the others I would suggest reading the [documentation](https://www.terraform.io/language/resources/syntax#meta-arguments) for more information

# Child Modules (aka Modules)

- A Module is just a folder full of Configuration Files that is deployed from a Root Module
- This allows you to reuse code
- The Module’s folder should include the usual suspects:  `main.tf`, `variables.tf`, `outputs.tf`
  - `main.tf` = where you specify the resources that will be created by the module
  - `variables.tf` = where you specify the variables that can be passed into the module when you call it
  - `outputs.tf` = where you specify the values that will be returned when the module is called
```terraform
# calling a child Module from your Root Module
module "someSymbolicName"  {
  source = “path/to/the/module/folder”

  key1 = value1
  key2 = value2
}

# reference an Output value that is generated by a Module
module.someSymbolicName.<outputName>
```
- The keys/value pairs are how you pass Input Variables to the Child Module
  - The Child Module defines what it accepts for Input Variables via its own `variables.tf` file in the Module's folder
- Tip: The `source` attribute could point to a git repo if you wanted
  - That way you could use git tags to create “versions” of your module, and then you can reference specific versions of each module
- Terraform also supports a number of *Meta-Arguments* that are available to use for each `module` block, such as `depends_on`, `count`, `for_each`, and `providers`
- This guide will go over the `count` and `for_each` meta-arguments.  But, for the others I would suggest reading the [documentation](https://www.terraform.io/language/modules/syntax#meta-arguments) for more information

### Module Notes
- Some Resource configuration can be provided as inline blocks inside a parent Resource, or it can be provided as totally separate top-level Resources
  - Take Subnets for an example.  Subnets could be defined as inline blocks on the Virtual Network resource, or Subnets could be defined as their own top-level resources
  - When coding your Modules, it is always preferred to use the separate top-level resources whenever possible
- Be careful when using the file() function inside of a Module, as the path to the file can get tricky.  Here are some special system variables that can help with this:
  - `path.module`:  references the folder where the child module is located
  - `path.root`:  references the folder of the root module

# Output Variables (aka Outputs)
Outputs are used when you want to output one or more values from one Terraform Root Module, and consume those values in a separate Terraform Root Module
```terraform
# defining an output
# remember, this is typically done in an outputs.tf file
output "name" {
  value       = azurerm_storage_account.someSymbolicName.id  # can be any terraform expression that you wish to output
  description = "put a good description here"
  sensitive   = true
}

# using an output
# outputs are displayed in the console after running certain terraform commands
# you can also use a Remote State Data Source (see above) to read Output Variables
```
- When defining an Output:
  - `value` is the only required parameter
  - Setting the `sensitive=true` parameter means that Terraform will not display the output’s value at the end of a `terraform apply`

---

# Syntax Notes

### String Interpolation
```terraform
"some string ${var.name} some more string"
```

### Comments
```terraform
# begins a single-line comment, this is the default comment style

// also begins a single-line comment

/* 
this is a 
multi-line comment
*/
```

# Loops

### count Meta-Argument
- Every Terraform `resource` or `module` block supports a meta-argument called `count`
- `count` defines how many copies of that item to create
- Example:
  ```terraform
  resource "azurerm_storage_account" "someSymbolicName" {
    count = 5
  }
  ```
- `count` must reference hard-coded values, variables, data sources, or lists.  It can NOT reference a value that needs to be computed
- When you specify the `count` meta-argument on a resource, you can use a new variable inside that resource:  `count.index`
  - `count.index` represents the number of the loop that you’re currently on
  - For example, say you had a resource with `count = 3`
    - The first resource will set `count.index = 0`
    - The second resource will set `count.index = 1`
    - The third resource will set `count.index = 2`
  - You can use this on resource parameters that are required to be unique:  `name = "resource-group-${count.index}"`
  - You can get creative with this by building a separate List variable that contains the values you would like to use inside of the resource that is using `count`
    ```terraform
    var.listOfNames = ["will", "dustin", "eleven"]
    
    resource "azurerm_storage_account" "someSymbolicName" {
      count = length(var.listOfNames)
      name  = var.listOfNames[count.index]
    }
    ```
- Important: When you use `count` on a resource, the resource now becomes a List
  - To reference a single instance of the resource created by count:  `azurerm_storage_account.someSymbolicName[2]`
  - To reference all instances of the resource created by count:  `azurerm_storage_account.someSymbolicName[*]` (this is called a "splat expression")

### Issue 1:  The `count` meta-argument is not supported on inline blocks
- For example, take this resource:
  ```terraform
  resource "someResource" "someName" {
    key1 = value1
    key2 = value2

    inline-block {
      keyA = valueA
      keyB = valueB
    }
  }
  ```
  - If you needed to create multiple inline-blocks, then you may be tempted to just put the `count` meta-argument on the inline-block.  However, that is NOT supported

### Issue 2:  Deleting a resource from the middle of a List is tricky
- For example, say you used `count = 4` to create some users:
  - `user[0] = arnold`
  - `user[1] = sylvester`
  - `user[2] = jean-claude`
  - `user[3] = chuck`
- Now, say you deleted the middle resource `sylvester`.  Every resource in the list after that will shift backwards in terms of index count, so you will be left with:
  - `user[0] = arnold`
  - `user[1] = jean-claude`
  - `user[2] = chuck`
  - This is a problem because terraform will need to delete the original `jean-claude[2]` and then create a new `jean-claude[1]`.  It will also have to delete the original `chuck[3]` and then create a new `chuck[2]`
- **If you remove an item from the middle of the List, Terraform will delete every resource after that item, and then it will recreate those resources again from scratch with new index values.**

### for_each Meta-Argument
- Every Terraform `resource` or `module` block supports a meta-argument called `for_each`
  ```terraform
  resource "azurerm_storage_account" "someSymbolicName" {
    for_each = var.Set or var.Map
  }
  ```
- So, if your var.Set or var.Map has 5 entries, then you'll get 5 different copies of that Resource
- List variables are NOT supported in Resource Block `for_each`.  But, you can convert a List variable to a Set variable:  `for_each = toset(var.List)`
- `for_each` must reference hardcoded values, variables, data sources, or lists.  It can NOT reference a value that needs to be computed
- When you specify the `for_each` meta-argument on a resource, you can use new variables inside that resource:  `each.key` and `each.value`
  - For a Set variable:
    - `each.key` and `each.value` are both set to the current item in the Set
    - Typically, you would just use `each.value`
  - For a Map variable:
    - `each.key` = the key of the current item in the Map
    - `each.value` = the value of the current item in the Map
- Important: When you use `for_each` on a resource, the resource now becomes a Map
  - To reference a single instance of the resource created by for_each:  `azurerm_storage.someName[key]`

### Benefit 1:  Deleting from the middle is no problem
- Since the resource is now considered a Map, deleting from the middle will no longer affect items further down the chain

### Benefit 2:  for_each is supported on inline blocks, by using a dynamic block
```terraform
resource "someResource" "someName" {
  key = value
    
  dynamic "<inlineBlockToDuplicate>" {
    for_each = any Collection var (list, set, map) or Structural var (tuple, object)

    content {
      key1 = <inlineBlockToDuplicate>.key
      key2 = <inlineBlockToDuplicate>.value
    }
  }
}
```
- So, if your Collection/Structural var has 5 entries, then you'll get 5 different copies of that Inline Block
- `dynamic` block `for_each` supports many types of variables, specifically Lists, Sets, Maps, Tuples, and Objects
- When you specify the `for_each` parameter on a `dynamic` block, you can use new variables inside that Inline Block:  `<inlineBlockToDuplicate>.key` and `<inlineBlockToDuplicate>.value`
  - For a Set variable:
    - `<inlineBlockToDuplication>.key` and `<inlineBlockToDuplication>.value` are both set to the current item in the Set
    - Typically, you would just use `<inlineBlockToDuplicate>.value`
  - For a List/Tuple variable:
    - `<inlineBlockToDuplicate>.key` = the numeric index of the current item in the List/Tuple
    - `<inlineBlockToDuplicate>.value` = the value of the current item in the List/Tuple
  - For a Map/Obect variable:
    - `<inlineBlockToDuplicate>.key` = the key of the current item in the Map/Object
    - `<inlineBlockToDuplicate>.value` = the value of the current item in the Map/Object

# For Expressions
- `for` expressions take an input of a List, Set, Tuple, Map, or Object
- `for` expressions will output either:
  - a Tuple if you use square brackets `[ ]`
  - an Object if you use curly brackets `{ }`

### [Square Brackets] return a Tuple

#### Input a List/Set/Tuple, return a Tuple
- `newTuple = [for <item> in var.List : <output> <condition>]`
  - `<item>` is the local variable name to assign to each item in the list/set/tuple
  - `<output>` is the value to put into the resultant Tuple, an expression that modifies `<item>` in some way
  - `<condition>` is optional and you could use it to further refine what values go into the resultant Tuple
- `newTuple = [for <index>, <item> in var.List : <output> <condition>]`
  - If your input is a List or Tuple, you can also use this format which gives you access to both the index value and the item value at the same time
- Example:
  - `newTuple = [for name in var.List : upper(name) if length(name) < 5]`
  - This looks at `var.List` and converts each entry to uppercase, returns only the names that are less than 5 characters, and stores the modified entries in `newList`

#### Input a Map/Object, return a Tuple
- `newTuple = [for <key>, <value> in var.Map : <output> <condition>]`
- The rest is the same as above
- Example:
  - `newTuple = [for first, last in var.Map : “${first} ${last}”]`
  - This pulls out each key/value pair from `var.map`, combines them into a new string separated by a space, and puts the new string values into `newTuple`

### {Curly Brackets} return an Object

#### Input a List/Set/Tuple, return an Object
- `newObject = {for <item> in var.List : <outputKey> => <outputValue> <condition>}`
  - `<item>` is the local variable name to assign to each item in the list/set/tuple
  - `<outputKey>` and `<outputValue>` is what to put into the resultant Object, they can be expressions that modify `<item>` in some way
  - `<condition>` is optional and you could use it to further refine what key/value pairs go into the resultant Object
- `newObject = {for <index>, <item> in var.List : <outputKey> => <outputValue> <condition>}`
  - If your input is a List or Tuple, you can also use this format which gives you access to both the index value and the item value at the same time

#### Input a Map/Object, return an Object
- `newObject = {for <key>, <value> in var.Map : <outputKey> => <outputValue> <condition>}`
- The rest is the same as above

# Template Directives
(WIP)

Template Directives are supported on regular Strings and Heredoc/Multi-line Strings.  It is recommended to only use them with Heredoc Strings so that you can use multiple lines for better readability

- This let’s you loop over a List variable or a Map variable
  ```terraform
  <<EOT
  %{ for <item> in <collection> }
  do something to <item>
  %{ endfor }
  EOT
  ```
- Strip Markers ( ~ ) allow you strip out unwanted spaces and newlines
  ```terraform
  <<EOT
  %{~ for blahblah }
  %{~ endfor }

  %{ for blahblahblah ~}
  %{ endfor ~}
  EOT
  ```
- This let’s you run an if statement within a string
  ```terraform
  <<EOT
  %{ if someCondition }
  value if true
  %{ endif }
  EOT
  ```
- You can also do an if/else statement
  ```terraform
  <<EOT
  %{ if some condition }
  value if true
  %{ else }
  value if false
  %{ endif }
  EOT
  ```

# Lifecycle Settings Meta-Argument
- Every terraform resource supports a `lifecycle` Meta-Argument block
- It can configure how that resource is created, updated, or deleted
```terraform
resource "azurerm_some_resource" "someName" {
  somekey = somevalue

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes        = [ attribute1, attribute2 ]
    
    # precondition & postcondition are supported in Terraform 1.2.0 and later
    # precondition & postcondition are supported only on `resource`, `data`, and `output` blocks

    # runs before the terraform apply
    precondition {
      # some condition that must resolve to either true or false
      # the condition can reference anything (even outside this resource)
      condition     = var.someVar < 3
      # an error message to show if the condition is false
      error_message = "There is a problem, variable someVar is greater than 3"
    }
    
    # runs after the terraform apply
    postcondition {
      # some condition that must resolve to either true or false
      # postcondition can reference itself by using the 'self' keyword
      condition     = length(self.zones) > 5
      # an error message to show if the condition is false
      error_message = "Something is wrong, zones must be greater than 5"
    }
  }
}
```
- `create_before_destroy`
  - By default, when terraform must replace a resource, it will first delete the old/existing one, and then it will create the new one after that
  - If your old/existing resource is being referenced by other resources, then terraform will not be able to delete it
  - The `create_before_destroy` option flip-flops this, so terraform will first create the new resource, update any references that are needed, and then delete the old/existing resource
- `prevent_destroy`
  - The `prevent_destroy` option will cause Terraform to exit on any attempt to delete that resource
- `ignore_changes`
  - This is a list of resource attributes that you want Terraform to ignore.  If the value of that attribute differs in real life vs. the Terraform code, then Terraform will just ignore it and not try to make any changes

# terraform CLI Commands
(WIP)
- `terraform apply`
  - work in progress
- `terraform console`
  - Interactive, read-only console to try out built-in functions, query the state of your infrastructure, etc.
- `terraform destroy`
  - Deletes all resources
  - There is no "undo" so be very careful!
- `terraform fmt`
  - work in progress
- `terraform graph`
  - Shows you the dependency graph for the resources
  - It outputs into a graph description language called DOT
  - You can use tools like Graphviz or GraphvizOnline to convert into an image
- `terraform import`
  - work in progress
- `terraform init`
  - Downloads any Providers that are found in your code, and puts them here:  `<currentDirectory>\.terraform\`
  - You must run `init` each time you change settings for your Remote Backend
  - You must run `init` each time you reference a new Module, or change Module settings
- `terraform output`
  - Lists all of the Output Variables
  - List a specific Output Variable only:  `terraform output <name>`
    - Tip:  this is great for scripts where you may need to grab an output variable from terraform and use it somewhere else.
- `terraform plan`
  - work in progress
- `terraform state`
  - work in progress
- `terraform workspace`
  - To work with terraform workspaces

# .gitignore File
(WIP)
- `.terraform`
  - Terraform’s scratch directory, is created inside each config folder where you run `terraform init` and includes the downloaded providers.
- `*.tfstate`
  - Local state files, never check these into version control as they contain secrets in clear text
- `*.tfstate.backup`
  - Backups of local state files
- `backend.hcl`
  - The standard filename when you use partial configuration for Remote Backend.
  - You only need to ignore this if you're storing **sensitive** keys/values in this file.

---

# References
- [Terraform Up and Running](https://www.terraformupandrunning.com/)
- [Terraform Settings](https://www.terraform.io/language/settings)
- [Provider Requirements](https://www.terraform.io/language/providers/requirements)
- [Version Constraints](https://www.terraform.io/language/expressions/version-constraints)
- [Type Constraints](https://www.terraform.io/language/expressions/type-constraints)
