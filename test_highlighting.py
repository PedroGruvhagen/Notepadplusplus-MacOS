# Test file for Python syntax highlighting
import os
import sys
from datetime import datetime

def main():
    """Main function"""
    print("Testing Python highlighting")
    
    # Keywords should be highlighted
    if True:
        for i in range(10):
            print(i)
    
    try:
        result = 42
    except Exception as e:
        pass
    
    return result

class TestClass:
    def __init__(self):
        self.value = "test"

if __name__ == "__main__":
    main()