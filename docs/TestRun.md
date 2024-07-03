[^Front Page](..)

[<Installation and Preparation](Installation.md)

---

# Test Run

To ensure that the containers and scripts of this workflow are working correctly on your system a subset of data from HG002 (21q22.11) is available. Before testing the workflow, ensure that you have changed the Working_Directory to the full path of the `test` directory. The workflow can be tested using the test data with the below, requiring srun to run:

`test/run-tests.sh [Assembler] [Mode]`

Where [Assembler] is either `hifiasm` or `verkko` and [Mode] is either `hic` or `kmer`. Each step of the workflow will be tested to ensure everything is operating correctly. Note that running Verkko on the test data using HiC phasing data will not produce a phased assembly due to limitations with this test data and the Assembler. 

---

[Assembly>](Assembly.md)
