# Small Cat (scat)
A small (112 bytes) `cat` program written in assembly for my amusement.

The exit code will reveal any issues.  
0: Everything is good  
1: Write error  
2: Couldn't open the file or no file provided  
3: Read error  

### Build instructions
nasm -f bin scat.asm  
From this you get a 64bit linux binary

### F.A.Q
Q: Why is it called Small Cat?  
A: Because it's small. And because it's funny.  
