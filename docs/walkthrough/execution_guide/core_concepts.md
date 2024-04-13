# Core Concepts

Before the execution flow by `request`, below outlines essential concepts for working with [NovaScope](https://seqscope.github.io/NovaScope/).

## Rule Dependencies
The rule dependencies are determined based on the **input and output files** specified in the rules. For example, if Rule `sbcd2chip` requires the output of Rule `fastq2sbcd` as input, the Rule `fastq2sbcd` serves as a prerequisite rule to Rule `sbcd2chip`. 

## Execution Dynamics

The execution of rules within [NovaScope](https://seqscope.github.io/NovaScope/) is governed by several key factors, outlined as follows:

- **Specified Final Output Files**: The execution of rules is directly influenced by the final output files requested by the user, as defined by the `Request` field in the [job configuration](../../getting_started/job_config.md) file. For instance, if the output of a rule (referred to as `Rule X`) is indicated as the final output file, then `Rule X` will be executed.

- **Rule Dependencies and Availability of Intermediate Files**: [NovaScope](https://seqscope.github.io/NovaScope/) initiates a systematic evaluation, starting with `Rule X`, to ascertain the presence of its required input files. If any inputs are missing, [NovaScope](https://seqscope.github.io/NovaScope/) iteratively identifies and executes the necessary precursor rules to generate these missing inputs, thus ensuring `Rule X` has everything it needs to proceed.

- **User-Defined Execution Options**: Snakemake provides a suite of command-line arguments that allow users to tailor the execution process of the pipeline. Below includes a selection of frequently utilized execution options. For all available execution options and their functionalities, please consult the [official Snakemake documentation](https://snakemake.readthedocs.io/en/stable/index.html).
    - `--rerun-incomplete` and `--ignore-incomplete`: These options dictate whether to rerun or ignore jobs that started but did not complete successfully in previous attempts.
    - `--restart-times`: This option sets the maximum number of attempts to restart a failing job before it is considered unsuccessful.
    - `--forceall`, `-F`: This option compels the execution of all rules, irrespective of their current completion status.

## Rulegraph
A rulegraph visually maps the rules to be executed alongside their dependencies. 

- **Components**: A rulegraph represents each rule as a node, with directed edges showing how the output of one rule serves as the input for another, establishing a clear path of data flow and execution order. 
- **Rule Status**: Solid lines depict rules set to be executed, while dotted lines indicate rules that will be skipped, as their outputs are already up to date. 

By demonstrating the workflow's structure, highlighting the sequence in which tasks are performed and how they interconnect, a rulegraph help understand the entire process from start to finish.
