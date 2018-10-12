# BookGapCheck

BookGapCheck.ahk  -  version 2018-10-12  -  by Nod5  -  GPLv3  

Quickly check if there are gaps or duplicates in a set of book page scan images.  

![Alt text](images/BookGapCheck1.png?raw=true)

![Alt text](images/BookGapCheck2.png?raw=true)

[larger image](images/BookGapCheck2_large.png)

![Alt text](images/BookGapCheck3.jpg?raw=true)

## How to use  

1. Drag and drop a jpg/tif/png from a folder with book page scan images.  
2. Click and draw a rectangle around the page number.  
3. BookGapCheck shows the same area from every 10th image in an overview image grid.  

If all grid image numbers increment by 10 then the set of scanned pages is likely complete. 
Example: 10 20 30 40 ... 480 .  

Output file format: gridimage_20181004174937.jpg  

Output is saved to same folder as input image.  
Custom output folder can be set on help screen.  

## Example: likely no gap or duplicate  

![Alt text](images/BookGapCheck4.jpg?raw=true)

## Example: gap

![Alt text](images/BookGapCheck5.jpg?raw=true)

## Feedback  
GitHub , https://github.com/nod5/BookGapCheck  
