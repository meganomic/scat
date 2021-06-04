# Small Cat (scat)
A small (112 bytes) 64bit `cat` program written in assembly for my amusement.  
scat32.asm contains a 32bit version that uses sendfile with the limitations that implies which results in a 58 byte exexecutable.

### Usage
**scat** [filename]  
If an error occurs it should™ just not print anything.

### Build instructions
nasm -f bin scat.asm

### F.A.Q
Q: Why is it called Small Cat?  
A: Because it's small. And because it's funny.  
