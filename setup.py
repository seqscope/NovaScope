from setuptools import setup, find_packages

setup(
    name="NovaScope",
    version="1.0.0",
    author="Weiqiu Cheng",
    author_email="weiqiuc@umich.edu",
    description="The pipeline for processing Novaseq spatial transcriptomics data",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "snakemake",
        # Add other dependencies here
    ],
    scripts=[
        'scripts/bricks.py',
        'scripts/rgb-gene-image.py',
        'scripts/rule_a1.build-spatial-barcode-dict.py',
        'scripts/rule_a2.sbcd_section_from_lane.py',
        'scripts/rule_a4.align-reads.py',
        'scripts/rule_general.py',
        'scripts/utils.py',
    ],
    entry_points={
        'console_scripts': [
            'novascope=novascope.__main__:main',  # Adjust according to your main entry point
        ],
    },
    package_data={
        '': ['*.smk', '*.yaml', '*.md', '*.pdf', '*.png', 'installation/*', 'docs/*', 'slurm/*'],
    },
    zip_safe=False,
)
