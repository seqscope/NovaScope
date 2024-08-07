# Core Concepts

Before the execution flow by `request`, below outlines essential concepts for working with [NovaScope](https://seqscope.github.io/NovaScope/).

## Basics
### Workflow
A workflow in Snakemake represents a structured sequence of steps designed to process data from start to finish. It defines how data moves through various stages of transformation, ensuring that each step is executed in the correct order. The workflow encompasses all tasks, from data input to the final output, automating the entire process to ensure consistency and reproducibility.

### Rule
Rules are the building blocks of a Snakemake-based workflow. Each rule specifies a discrete task within the workflow, detailing how to transform input files into output files.

### Rule Dependencies
The rule dependencies are determined based on the **input and output files** specified in the rules. For example, if Rule `sbcd2chip` requires the output of Rule `fastq2sbcd` as input, the Rule `fastq2sbcd` serves as a prerequisite rule to Rule `sbcd2chip`.

### Directed Acyclic Graph (DAG)
A Directed Acyclic Graph (DAG) is a visual representation of the rule dependencies within a Snakemake workflow. It shows how different tasks are connected and the sequence in which they must be executed. The DAG helps in understanding the workflow’s structure, optimizing task execution, and troubleshooting any issues that arise.

### Rulegraph
A rulegraph visually maps the rules to be executed alongside their dependencies. 

- **Components**: A rulegraph represents each rule as a node, with directed edges showing how the output of one rule serves as the input for another, establishing a clear path of data flow and execution order. 
- **Rule Status**: Solid lines depict rules set to be executed, while dotted lines indicate rules that will be skipped, as their outputs are already up to date. 

By demonstrating the workflow's structure, highlighting the sequence in which tasks are performed and how they interconnect, a rulegraph help understand the entire process from start to finish.
tion status.

### Dry Run 
A "dry run" is an execution mode where the workflow is planned and validated without actually running any of the commands or scripts. It allows users to see what actions Snakemake would take, including the dependencies it resolves and the order in which rules would be executed, but no actual data processing occurs.
```bash
snakemake --dry-run
```

## Execution Dynamics

The execution of rules within [NovaScope](https://seqscope.github.io/NovaScope/) is governed by several key factors, outlined as follows:

### Specified Final Output Files
The execution of rules is directly influenced by the final output files requested by the user, as defined by the `Request` field in the [job configuration](../../basic_usage/job_config.md) file. For instance, if the output of a rule (referred to as `Rule X`) is indicated as the final output file, then `Rule X` will be executed.

### Availability of Intermediate Files
During execution, [NovaScope](https://seqscope.github.io/NovaScope/) traces the final output file back through the rule dependencies to identify all necessary rules for execution. Specifically, NovaScope recursively resolves the dependencies for each rule, starting from the final output and identifies the required inputs and the rules that produce them until it reaches rules with no dependencies, resulting in an execution plan ensures each rule is executed only after all its dependencies are met. Thus, in addition to the specified final output files, NovaScope generates output files from all necessary rules during execution.

### User-Defined Execution Options

Snakemake provides a suite of command-line arguments that allow users to tailor the execution process of the pipeline. Below includes a selection of frequently utilized execution options. For all available execution options and their functionalities, please consult the [official Snakemake documentation](https://snakemake.readthedocs.io/en/stable/index.html).

 - `--rerun-incomplete` and `--ignore-incomplete`: These options dictate whether to rerun or ignore jobs that started but did not complete successfully in previous attempts.
- `--restart-times`: This option sets the maximum number of attempts to restart a failing job before it is considered unsuccessful.
- `--forceall`, `-F`: This option compels the execution of all rules, irrespective of their current comple