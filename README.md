# IaC Bootstrap

Multi-Cloud Infrastructure as Code bootstrap repository

## Motivation

Every time when you start a new IaC project, you have to answer a lot of
questions - how to organize your code files? how to manage state-files?
do I have to run terraform locally or do I need a CI server for that?
There are no standardized way to organize your code.
This repository serves as a starting point for your Infrastructure as Code
based on [Terraform](https://terraform.io) and [Terragrunt](https://terragrunt.gruntwork.io/).

No matter what cloud provider you are using, you will keep all of your code
files in one place. In fact this is not a real cloud-agnostic solution,
because the code for different cloud providers is various due to different
resources and their specifics. Anyway you still be able to use the same syntax,
constructions, and code style for it.

## Features

* Easiest way to start your project from scratch
* A tons of documentation inside
* Minimum requirements - you only need docker installed


## Structure

* [live](live/README.md) *configuration files mirroring your live infrastructure*
    * [live/aws-acme](live/aws-acme/README.md) *AWS account #1*
        * [live/aws-acme/global](live/aws-acme/global/README.md) *region-independent services*
        * [live/aws-acme/us-east-1](live/aws-acme/us-east-1/README.md) *region specific*
    * [live/gcp-foobar](live/gcp-foobar/README.md) *Google account #1*
        * [live/gcp-foobar/global](live/gcp-foobar/global/README.md) *region-independent services*
        * [live/gcp-foobar/us-west1](live/gcp-foobar/us-west1/README.md) *region specific*
* [modules](modules/README.md) *community modules, infrastructure micro-modules*
    * [modules/aws-data](modules/aws-data/README.md) *example of AWS specific module*
    * [modules/gcp-data](modules/gcp-data/README.md) *example of Google specific module*


## Quick start

* clone the repository
* check nested *terragrunt.hcl* files for correct settings
* run *make build* to build docker image with required utilities
* add some code
* run *make plan* to evaluate terraform intentions

## Feedback

[Suggestions and improvements](https://github.com/repconn/iac-bootstrap/issues)
