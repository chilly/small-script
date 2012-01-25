import os,re,sys

def decode_file(filename, decoding):
	f = open(filename,'r')
	content = f.read().decode(decoding)
	f.close()
	return content
def write_file(filename, string, encoding):
	f = open(filename,'w')
	f.write(string.encode(encoding))
	f.close()
def rewrite_file(filename, destFilename, decoding, encoding):
	content = decode_file(filename, decoding)
	write_file(destFilename, content, encoding)
""" 
return a file path list, and not include hidden file
"""
def find_all_file(path, matcher = None):
	pathlist = []
	for filename in os.listdir(path):
		temp = os.path.join(path, filename)
		if os.path.isdir(temp):
			subPathList = find_all_file(temp, matcher)
			pathlist.extend(subPathList)
		else:
			if matcher.match(filename) != None: 
				pathlist.append(temp)
	return pathlist


if __name__ == '__main__':
	srcDir = sys.argv[1]
	print srcDir
	destDir = srcDir
	matcher = '\w+\.\w+'
	matcher = re.compile(matcher)
	encoding = 'utf-8'
	decoding = 'gbk'
	if os.path.isdir(srcDir):
		for filepath in find_all_file(srcDir, matcher):

			destFilePath = destDir+filepath[len(srcDir):]
			print filepath, destFilePath
			try:
				rewrite_file(filepath, destFilePath, decoding, encoding)
			except:
				pass
	else :
		rewrite_file(srcDir, destDir, decoding, encoding)		
