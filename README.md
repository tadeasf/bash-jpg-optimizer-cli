# Image Optimizer CLI

A command-line tool for optimizing high-quality JPEG images from DSLR/mirrorless professional cameras for web app photo portfolios.

## Features

- Resize images while maintaining aspect ratio
- Adjust image quality (compressed, balanced, or high quality)
- Process multiple images in parallel
- Handle duplicate filenames
- Optional recursive directory search

## Installation

1. Download the `jpg-optimizer` script.
2. Make it executable: `chmod +x jpg-optimizer`
3. Move it to a directory in your PATH: `sudo mv jpg-optimizer /usr/local/bin/`

## Usage

1. Open a terminal and navigate to the directory containing your images.
2. Run the script: `jpg-optimizer`
3. Follow the prompts to specify:
   - Input directory
   - Longest side dimension (in pixels)
   - Quality setting (compressed/balanced/quality)
   - Output directory

For recursive directory search, use the `-r` flag: `jpg-optimizer -r`

## How it works

1. The script uses ImageMagick to process images.
2. Images are resized to fit within the specified dimensions while maintaining aspect ratio.
3. Quality settings adjust compression and sampling factors:
   - Compressed: 85% quality
   - Balanced: 4:2:0 sampling, 95% quality
   - Quality: 4:2:2 sampling, 98% quality
4. Processed images are saved to the output directory.
5. Duplicate filenames are handled by adding an index and storing in a "duplicates" subdirectory.

## Requirements

- Bash
- ImageMagick
- GNU Parallel

## Author

https://github.com/tadeasf