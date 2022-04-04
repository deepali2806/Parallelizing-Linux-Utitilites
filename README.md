# Parallelizing-Linux-Utitilites
In this project, linux utilities like **Grep** and **Sort** are parallelized on GPU using CUDA.\
In Linux, grep is used for pattern matching of input string from a file of strings. It uses Boyer Moore pattern matching algorithm on a chunk of data. 
Usage : 
````
grep "pattern" filename
````
While sort command is used for sorting a file where each element is a line of string. It uses external R-way merge sort. 
Usage : 
````
sort filename
```` 
An attempt is made to parallelize these operation using CUDA GPU with naive and some optimized algorithms.\
For grep function, initially naive pattern matching is implmented. Further it is optimized to use Boyer Moore pattern matching algorithm for improved efficiency.
Each line in the file is considered as a input string to each thread.\
Similarly, for sort function initially naive string sort i.e. Odd-even sort is being used on strings.
Then there is a very simple implmentation of paper
[Can GPUs sort strings efficiently!](https://ieeexplore.ieee.org/abstract/document/6799129) using **Thrust** library functions from CUDA\
This optimized sort gives impressive performance advantage.

Pefromance comparison table for sequential and parallel GPU code is added here:
![alt text](https://github.com/deepali2806/Parallelizing-Linux-Utitilites/blob/main/images/GPU.png)

