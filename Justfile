set shell := ["nu", "-c"]

# List all the just commands
default:
    @just --list

genks:
  nu ./gen_kustomization.nu 
