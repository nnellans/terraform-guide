Warning: This is an advanced guide.  It assumes you already know the basics of Terraform, and it is not very beginner-friendly.  Think of this like an advanced cheat sheet.  I went through the HashiCorp documentation, as well as various books, and captured any notes that I felt were relevant or important.  Then, I organized them into the README file you see here.

It's important to know that this is a live document.  Some of the sections are still a work in progress.  I will be continually updating it over time.

If you are new to Terraform, then I would suggest first going through the [HashiCorp Docs](https://www.terraform.io/docs) or doing a couple [HashiCorp Learn](https://learn.hashicorp.com/) courses.

---

# Table of Contents

This guide goes over a lot of things, and I tried my best to organize them in a logical manner.

Part 1 - Terraform Files, Folder Structure, and Common Code Blocks
- [Configuration Files](README.md#configuration-files)
- [Root Module](README.md#root-module)
- [Folder Structure](README.md#typical-root-module-folder-structure)
- [Common Code Blocks](README.md#common-code-blocks)

Part 2 - Terraform State
- [State Files](README.md#state-files)
- [Local Backend](README.md#local-backend)
- [Remote Backend](README.md#remote-backend)
- [Terraform Workspaces](README.md#terraform-workspaces)

Part 3 - Terraform Code Blocks
- [Input Variables](README.md#input-variables-aka-variables)
- [Local Values](README.md#local-values-aka-locals)
- [Data Sources](README.md#data-sources)
- [Resources](README.md#resources)
- [Modules](README.md#modules)
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
- Files that contain Terraform code are officially called "configuration files"
- Configuration Files can be written in the typical, native format which uses the `.tf` file extension, or they can be written in the alternate JSON format which uses the `.tf.json` file extension.
- The alternate JSON format is quite rare and you won't see if very often.  So, this guide will be focused strictly on the native format using the `.tf` file extension

### Root Module
- When you run Terraform CLI commands such as `plan` or `apply` you run it against a directory of Configuration Files.  This directory could contain just a single Configuration File, or this directory could contain multiple Configuration Files
- Separating your Terraform code into multiple Configuration Files is totally optional and for you to decide.  Note that using multiple Configuration Files can make it easier for code readers and code maintainers
- Terraform will automatically evaluate ALL Configuration Files that it finds in the **top level** of the directory you run it against
- This top-level directory is commonly referred to as the "Root Module"

### Typical Root Module Folder Structure
- `main.tf`
  - Contains all of your `locals` blocks, `resource` blocks, `module` blocks, `data` blocks
- `outputs.tf`
  - Contains all of your `output` blocks
- `variables.tf`
  - Contains all of your `variable` blocks
- `versions.tf`, `terraform.tf`, `provider.tf`
  - Recently, it has been common to put the `terraform` configuration block and all of your `provider` configuration blocks into separate Configuration Files
  - Some of the common filenames that are used for this are `versions.tf`, `terraform.tf`, and `provider.tf`
  - You may not always find these files.  If they don't exist, then these blocks are typically found at the top of `main.tf` instead

### Common Code Blocks
Your Terraform code will include multiple different types of blocks.

There are some that configure settings on your environment, like the `terraform` block and the `provider` blocks.

There are blocks that actually create resources, like the `resource` and `module` blocks.

Then, there are blocks that deal with input variables (`variable`), local values (`locals`), data sources (`data`), and outputs (`output`).

### terraform block
```terraform
terraform {

  required_version = "=1.2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.7.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.22.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "value"
    storage_account_name = "value"
  }

}
```
- This is a pretty important block where you can specify various Terraform settings
- This block supports hard-coded values only
- The `required_version` parameter is used to specify which version(s) of Terraform CLI are supported by this Root Module.  You can say that only a specific version is supported, or you can specify a minimum version, maximum version, or even a range of versions.  See the [Version Constraints](https://www.terraform.io/language/expressions/version-constraints) documentation for more information
- The `required_providers` block declares which providers are used by this Root Module, so that Terraform CLI can install these Providers and use them.  This also allows you to specify which versions of each Provider are supported by your code.  There are a lot of nuances to the `required_providers` block and I would recommend reading the [Provider Requirements](https://www.terraform.io/language/providers/requirements) documentation for more information
- The `backend` block is used to configure which Backend the Terraform CLI will use to store the State File.  More information on Backends can be found later in this guide
- The `terraform` block has a few other uses, but they will not be covered here.  Read the [Terraform Settings](https://www.terraform.io/language/settings) documentation for more information

### provider blocks
```terraform
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "second"
  region = "us-west-2"
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = "acme-app"
  region  = "us-central1"
}
```
- Providers are what allow Terraform CLI to talk to the APIs of Cloud vendors, SaaS vendors, and other vendors.  For example, the `aws` Provider allows Terraform to create AWS resources and use AWS data sources
- Each Provider may have its own unique settings that you must configure in order to talk to that vendor's API.  This may include things such as the credentials used to authenticate to the vendor's API, which region to use, which subscription to use, etc.
  - Do not put sensitive credentials directly in the `provider` block.  Again, passwords stored directly in code are bad!  Some Providers support alternate ways to provide these values, like using environment variables, and it is recommended to use these alternate methods.  Check out the documentation for your specific Provider for more information on what is supported by your Provider.
- You may still occassionally see code that uses the `version` parameter inside of a `provider` block.  It's important to know that this is deprecated, do NOT use this.  Instead, you should specify the supported Provider versions in the `terraform` block (see above).
- You can declare multiple `provider` blocks for a single Provider, each block using a different configuration.  See the 2 aws blocks in the example above.
  - The first instance you define is considered the "default" Provider and does not need to use the `alias` parameter
  - Any other instances you define must have a unique `alias` parameter that will be used to reference this instance
- Read the [Provider Configuration](https://www.terraform.io/language/providers/configuration) documentation for more information

---

# Terraform State

### State Files
- State Files use a custom JSON format
- You should NEVER manually edit State Files.  Instead, use commands like `terraform import` and `terraform state` to modify the state
- You should NEVER store your State Files in Version Control Systems like Git:
  - State Files often include passwords and other sensitive information
  - State Files are stored in plain text!
  - You do NOT want a file like this stored in your Git repository
- Make sure your State Files are stored in a secure location and accessible only by users or accounts who require access

### Local Backend
- This is the default backend that Terraform CLI will use unless you specify a different backend
- This is just a file named `terraform.tfstate` that is automatically created in the Root Module
- Problems with a Local Backend:
  - The State File is local to your computer and can not be shared by other teammates
  - You can only use 1 local State File
    - (Workspaces are an exception, but they are not recommended)
- You can start with a Local Backend, and later you can change your code to use a Remote Backend instead. Terraform CLI will recognize the local State File and prompt you to copy it to the new Remote Backend

### Remote Backend
- A Remote Backend stores your State Files in remote shared storage (like Azure Storage, AWS S3, etc.)
- Most Remote Backends support:
  - Encryption at rest
  - Encryption in transit
  - File locking, so only 1 person can run a `terraform apply` command at a time
- You can only configure 1 Remote Backend per Root Module
- Configuring a Remote Backend is done in the `backend` block inside the root `terraform` block:
  ```terraform
  terraform {
    backend "azurerm" {
      key1 = value1
      key2 = value2
      key3 = value3
    }
  }
  ```
- The keys & values shown above are specific to the type of Remote Backend (in this case `azurerm`).  They specify:
  - How to find the storage (name, resource group, etc.)
  - How to authenticate to the storage (service principal, access key, etc.)
  - Read the documentation for your chosen Remote Backend type for more information
- `backend` blocks can NOT use Terraform variables or references, they must use hardcoded values
  - This is because Terraform CLI sets the Remote Backend as the very first step, even before it processes variables
  - Do NOT put sensitive values directly in the `backend` block
  - You can remove some or all of the key/value pairs from the `backend` block and provide them in other ways:
    - Option 1 is individual key/value pairs:  `terraform.exe -backend-config="key=value" -backend-config="key=value"`
    - Option 2 is to use a separate file:  `terraform.exe -backend-config=backend.hcl`
      - Where `backend.hcl` is a file which contains only the key/value pairs that are needed by the backend
      - Do NOT check this file into version control if it contains sensitive values
    - Option 3 is setting special environment variables that the Remote Backend will automatically read from.  The environment variables must be set on the computer where terraform CLI will be run.  Each Remote Backend supports its own special environment variables.  Check the docs for your Remote Backend of choice for more information
      - This is the preferred option, as credentials are kept out of your code

### Terraform Workspaces
- You may want to consider these as 'local' Workspaces, as they are different from Terraform Cloud Workspaces
- If you create Workspaces, they each get their own State File.  However, all Workspaces will still share the same Backend
- State Files for Workspaces are placed in a new subfolder called `env:` and each Workspace gets its own subfolder under that:
  - `<backend>\env:\workspace1\terraform.tfstate`
  - `<backend>\env:\workspace2\terraform.tfstate`
- Switching Workspaces is equivalent to changing the path where your State File is stored
- In general, these are confusing.  It can be easy to mix up Workspaces and forget which one you are currently working with
- If possible, stay away from using these!

---

# Input Variables (aka Variables)

```terraform
# defining a variable
# remember, this is typically done in a variables.tf file
variable "exampleVarName" {
  description = "put a good description here"
  type        = string | number | bool | list | tuple | set | map | object | any
  default     = set a default value here
}

# use a variable by prefixing the variable's name with var.
var.exampleVarName
```
- When defining a Variable, all three parameters are optional
  - If `type` is omitted, then the default is `any`
- `type` can be a combination of different options:  `list(number)`

### How to set values of Variables:
- You can set a `default` value inside the Variable definition
- Set an environment variable with the name of `TF_VAR_<varName>` and the value that you want
  - Linux: `export TF_VAR_varName=value`
  - PowerShell: `$env:TF_VAR_varName = 'value'`
- Using a file with a `.tfvars` extension that lists Variable names and their values
  - Option 1: Terraform CLI will automatically load your file if it is placed in your Root Module and it is named `terraform.tfvars` or `*.auto.tfvars`
  - Option 2: Pass your tfvars file with the `-var-file` switch: `terraform.exe plan -var-file=somefile.tfvars`
- You can pass a value with the `-var` switch: `terraform plan -var "name=value"`
- If not set by any other method, then Terraform CLI will interactively prompt you for a value when you run `terraform apply`
- Values are loaded in the following order, with the later options taking precedence over earlier ones:
  - Environment Variables
  - `terraform.tfvars` files
  - `*.auto.tfvars` files
  - `-var` and `-var-file` commandline options, in the order they are given

# Variable Types

### List Variables
- `type = list(string)` This defines a List of all Strings
- `type = list(number)` This defines a List of all Numbers
- `type = list`
  - This shorthand is not recommended any more.  Instead, use `list(any)`
  - When using `list` or `list(any)` the List values must still all be the same Type (string, number, etc.)
- Setting the value of a List variable, two options:
  - Put each value on its own line, separated by commas
    ```terraform
    listName = [
      "first",
      "second",
      "third"
    ]
    ```
  - Put all values on a single line, also separated by commas
    ```terraform
    listName = [ "first", "second", "third" ]
    ```
  - A comma after the last value is allowed, but not required
- Using a specific value from the List:  `var.listName[3]`
- Lists are zero-based, so the the first entry is always index 0:  `var.listName[0]`
- Some example List Functions:
  - Find the number of items inside a list:  `length(var.listName)`

### Tuple Variables
- This is the 'structural' version of a List variable
- It allows you to define a schema (within square brackets), allowing you to use different variable Types inside the Tuple (instead of being restricted to the same variable Type when using a List)
  - `type = tuple( [schema] )`
  - Example: `type = tuple( [ string, number, bool ] )`

### Map Variables
- `type = map(string)` This defines a Map where all the values are Strings
  ```terraform
  mapName = {
    stringKey = "stringValue"
    stringKey = "stringValue"
  }
  ```
- `type = map(number)` This defines a Map where all the values are Numbers
  ```terraform
  mapName = {
    stringKey = numberValue
    stringKey = numberValue
  }
  ```
- `type = map(list(string))` This defines a Map where all the values are Lists of Strings
  ```terraform
  mapName = {
    stringKey = [ "string", "string" ]
    stringKey = [ "string", "string" ]
  }
  ```
- `type = map`
  - This shorthand is not recommended any more.  Instead, use `map(any)`
  - When using `map` or `map(any)` the Map values must still all be the same Type (string, number, etc.)
- Important: Keys are always strings.  Quotes may be omitted on the keys (unless the key starts with a number, in which case quotes are required)
- Setting the value of a Map variable, two options:
  - Put each pair on its own line, separated by line breaks:
    ```terraform
    mapName = {
      key1 = value1
      key2 = value2
    }
    ```
  - For a single line, you must use commas to separate each pair:
    ```terraform
    mapName = { key1 = value1, key2 = value2 }
    ```
- You can use either equal signs `key1 = value1` or colons `key1: value1`.  However, `terraform fmt` doesn't work on the colon style
- Using a specific value from the Map, two options:
  - `var.mapName.key1`
  - `var.mapName["1key"]`
    - You must use this if the key begins with a number
- Some example Map Functions:
  - Return just the values from a Map:  `values(var.mapName)`

### Object Variables
- This is the 'structural' version of a Map variable
- It allows you to define a schema (within curly brackets), which can use different variable Types inside the Object (instead of being restricted to the same variable Type when using a Map)
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
- This approach makes your Configuration Files easier to read and understand. It avoids cluttering your resource definitions with logic
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
- Data Sources fetch up-to-date information from your providers (Azure, AWS, etc.) each time you run Terraform
- Each provider has their own list of supported Data Sources
- Data Sources are Read-Only!
- When defining a Data Source, the argument(s) that you specify can be thought of like search filters to limit what data is returned

# Other types of Data Sources

### Remote State Data Source
- Use these when you want to pull info from a foreign Terraform State File
- That foreign Terraform State must have some `outputs` already configured, because that's the information you're pulling from

#### Defining a Remote State Data Source
```terraform
data "terraform_remote_state" "name" {
  backend = "azurerm"
  config = {
    key1 = value1
    key2 = value2
  }
}
```
- In the `config` block you specify the storage and state file to connect to, as well as how to authenticate to that storage.  You can use the same parameters you used for the Remote Backend settings
- Partial config is NOT supported for Remote State Data Sources

#### Using a Remote State Data Source:
- `data.teraform_remote_state.<dataSourceName>.outputs.<outputName>`

### External Data Source
- Provides an interface between Terraform and an external program
- Example:
  ```terraform
  data "external" "example" {
    program = ["python", "${path.module}/example-data-source.py"]

    query = {
      # arbitrary map from strings to strings, passed to the external program as the data query.
      id = "abc123"
    }
  }
  ```
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
    - Terraform does not execute the program through a shell, so it is not necessary to escape shell metacharacters nor add quotes around arguments containing spaces
  - `query` is of type map(string)
    - Optional
    - These values are passed to the program as query arguments.
- How to reference the data created from the external data source:
  - `data.external.<name>.result.<someAttribute>`

### Template File Data Source

#### Defining a Template File Data Source
```terraform
data "template_file" "name" {
  template = file("somefile.txt")

  vars = {
    key1 = value1
    key2 = value2
  }
}
```
- The file you provide is processed as a string.  Any time a matching variable key is found in the string, it is replaced with the variable value specified
- The string must be formatted like this: `in this string ${key1} will be replaced and ${key2} will also be replaced`
- `template` could also be just a simple string value or string variable that you want to modify

#### Using a Template File Data Source
- Using the rendered output from a Template File Data Source:
  - `data.template_file.<dataSourceName>.rendered`

# Resources
- Resources are the most important element in the Terraform language.  Each `resource` block describes one or more infrastructure objects, such as virtual networks, compute instances, or higher-level components such as DNS records
```terraform
# defining a resource from the azurerm provider
resource "azurerm_storage_account" "someSymbolicName" {
  name     = "someName"
  location = "someLocation
}
```
- In the example above, the resource type is `azurerm_storage_account` and if we look at the beginning of the resource type we can tell that it comes from the `azurerm` Provider.  Each Provider supports its own set of resource types.  Each Provider also defines the acceptable parameters to use for each resource type.  Check your Provider's documentation to learn more about the supported resource types and their supported parameters.
- Terraform also supports a number of 'Meta-Arguments' that are available to use for each `resource` block, such as `depends_on`, `count`, `for_each`, `provider`, `lifecycle`, and `provisioner`
- Further below, this guide will go over the `count`, `for_each`, and `lifecycle` meta-arguments.  But, for the others I would suggest reading the [documentation](https://www.terraform.io/language/resources/syntax#meta-arguments) for more information.

# Modules

- A Module is just a folder full of Configuration Files that is deployed by a Root Module
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
```
- The keys/value pairs are how you pass Input Variables to the Child Module
- The Child Module defines what it accepts for Input Variables via its own `variables.tf` file in its own folder
- Tip: The `source` attribute could point to a git repo if you wanted
  - That way you could use git tags to create “versions” of your module, and then you can reference specific versions of each module
- Terraform also supports a number of 'Meta-Arguments' that are available to use for each `module` block, such as `depends_on`, `count`, `for_each`, and `providers`
- Further below, this guide will go over the `count` and `for_each` meta-arguments.  But, for the others I would suggest reading the [documentation](https://www.terraform.io/language/modules/syntax#meta-arguments) for more information.

### Reference an Output value that is generated by a Module
- `module.someSymbolicName.<outputName>`
- Tip: this could then be used in the Root Module’s outputs.tf

### Module Notes
- Some Provider resources allow you to configure certain settings either using inline blocks or by using totally separate top-level Resources.  For example, an Azure Virtual Network resource will let you create Subnets either through an inline block inside the Virtual Network resource, or it will let you create Subnets in their own top-level resource, totally separate from the Virtual Network resource.
  - For modules, it is preferred to use the separate top-level Resources whenever possible.  This allows you to create Subnets inside the Module as well as outside of the Module.
  - For example, when using separate top-level Resources, your Module might be coded to create 2 Subnets with top-level Resources.  On top of that, you could also choose to create 3 more Subnets by using top-level Resources outside of the Module.  But, if the Subnets were defined in the Module as inline blocks on the Virtual Network resource, then there would be no way to add extra Subnets outside of the Module
- Be careful when using the file() function inside of a Module, as the path to the file can get tricky.  Here are some special system variables that can help with this:
  - `path.module`:  references the folder where the child module is located
  - `path.root`:  references the folder of the root module

# Output Variables (aka Outputs)
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
- Outputs are used when you want to output a value or values from one Terraform Root Module, and consume those values in a separate Terraform Root Module
- When defining an Output:
  - `value` is the only required parameter
  - Setting the `sensitive=true` parameter means that Terraform will not display the output’s value at the end of a `terraform apply`

---

# Syntax Notes

### String Interpolation
```terraform
"some string ${var.name} some more string"
```

### Heredoc / multiline strings
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
- `count` must reference hard-coded values, variables, data sources, and lists.  It can NOT reference a value that needs to be computed
- When you specify the `count` meta-argument on a resource, then you can use a new variable inside that resource:  `count.index`
  - `count.index` represents the number of the loop that you’re currently on
  - For example, say you had a resource with `count = 3`
    - The first resource will set `count.index = 0`
    - The second resource will set `count.index = 1`
    - The third resource will set `count.index = 2`
  - You can use this on resource parameters that are required to be unique:  `name = "resource-group-${count.index}"`
  - You can get creative with this by building a separate List variable that contains the values you would like to use inside of the resource that is using `count`
    ```terraform
    var.listOfNames = ["peter", "paul", "mary"]
    
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
  - If you needed to create multiple inline-blocks, then you may be tempted to just put the `count` meta-argument inside the inline-block.  However, that is NOT supported

### Issue 2:  Deleting a resource from the middle of a List is tricky
- For example, say you used `count = 3` to create some users:
  - `user[0] = arnold`
  - `user[1] = sylvester`
  - `user[2] = jean-claude`
  - `user[3] = chuck`
- Now, say you deleted the middle resource `sylvester`.  Every resource in the list after that will shift backwards in terms of index count, so you will be left with:
  - `user[0] = arnold`
  - `user[1] = jean-claude`
  - `user[2] = chuck`
  - This is a problem because terraform will need to delete the original `jean-claude[2]` and then create a new `jean-claude[1]`.  It will also have to delete the original `chuck[3]` and then create a new `chuck[2]`
- **If you remove an item from the middle of the List, terraform will delete every resource after that item, and then it will recreate those resources again from scratch with new index values.**

### for_each Meta-Argument
- Every Terraform `resource` or `module` block supports a meta-argument called `for_each`
  ```terraform
  resource "azurerm_storage_account" "someSymbolicName" {
    for_each = var.Set or var.Map
  }
  ```
- So, if your var.Set or var.Map has 5 entries, then you'll get 5 different copies of that Resource
- List variables are NOT supported in Resource Block `for_each`.  You can convert a List variable to a Set variable:  `for_each = toset(var.List)`
- `for_each` must reference hardcoded values, variables, data sources, and lists.  It can NOT reference a value that needs to be computed
- When you specify the `for_each` meta-argument on a resource, then you can use new variables inside that resource:  `each.key` and `each.value`
  - For a Set variable:
    - `each.key` and `each.value` are both set to the current item in the Set
    - Typically, you would just use `each.value`
  - For a Map variable:
    - `each.key` = the key of the current item in the Map
    - `each.value` = the value of the current item in the Map
- When you use `for_each` on a resource, the resource now becomes a Map
  - To reference a single instance of the resource created by for_each:  `azurerm_storage.someName[key].id`

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
- `for_each` supports many types of variables, specifically Lists, Sets, Maps, Tuples, and Objects

> This is confusing.  To summarize the `for_each` support:<br>for_each on Resources/Modules: Sets and Maps only<br>for_each on Dynamic Blocks: Lists, Sets, Tuples, Maps, and Objects are supported

- When you specify the `for_each` parameter on an inline block, then you can use new variables inside that Inline Block:  `<inlineBlockToDuplicate>.key` and `<inlineBlockToDuplicate>.value`
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
  - This pulls out each key/value pair from `var.map`, combines them into a new string separated by a space, and puts the new string values into `newTuple

### {Curly Brackets} return an Object
- Notice that this uses curly brackets instead of square brackets
- Also notice the arrow sign `=>` separating `outputKey` & `outputValue`

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

# String Directives
(WIP)

### for Loops
- This let’s you loop over a List variable or a Map variable
  ```terraform
  <<EOF
  %{ for <item> in <collection> }
  do something to <item>
  %{ endfor }
  EOF
  ```
- Strip Markers ( ~ ) allow you strip out unwanted spaces and newlines
  ```terraform
  %{~ for blahblah }
  %{~ endfor }

  %{ for blahblahblah ~}
  %{ endfor ~}
  ```

### Conditionals
- This let’s you run an if statement within a string
  ```terraform
  %{ if someCondition }
  value if true
  %{ endif }
  ```
- You can also do an if/else statement
  ```terraform
  %{ if some condition }
  value if true
  %{ else }
  value if false
  %{ endif }
  ```

# Lifecycle Settings Meta-Argument
- Every terraform resource supports a `ifecycle` Meta-Argument block
- It can configure how that resource is created, updated, or deleted.
```terraform
resource "azurerm_some_resource" "someName" {
  key = value

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes        = [ attribute1, attribute2 ]
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
  - Looks at the current folder, and deletes all resources
  - There is no "undo" be very careful!
- `terraform fmt`
  - work in progress
- `terraform graph`
  - Looks at the current folder, and shows you the dependency graph for the resources
  - It outputs into a graph description language called DOT
  - You can use Graphviz or GraphvizOnline to convert into an image
- `terraform import`
  - work in progress
- `terraform init`
  - Downloads any Providers that are found in your code, they are put here:  `<currentDirectory>\.terraform\`
  - You must run `init` each time you change settings for your Remote Backend
  - You must run `init` each time you reference a new Module, or change Module settings
- `terraform output`
  - Looks at the current folder, and lists all of the Output Variables
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
