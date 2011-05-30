#!/usr/bin/env python
# -*- coding: utf-8 -*-

#   pg-cicero - PostgreSQL Documentation Translation Project
#   Copyright (C) 2011  2ndQuadrant Italy <info@2ndquadrant.it>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

import sys
from collections import deque
from cStringIO import StringIO
import os

entity_list = {
    'aacute':'á',
    'Aacute':'Á',
    'ouml':'ö',
    'Ouml':'Ö',
    'acirc':'â',
    'Acirc':'Â',
    'szlig':'ß',
    'agrave':'à',
    'Agrave':'À',
    'uacute':'ú',
    'Uacute':'Ú',
    'aring':'å',
    'Aring':'Å',
    'ucirc':'û',
    'Ucirc':'Û',
    'atilde':'ã',
    'Atilde':'Ã',
    'ugrave':'ù',
    'Ugrave':'Ù',
    'auml':'ä',
    'Auml':'Ä',
    'uuml':'ü',
    'Uuml':'Ü',
    'aelig':'æ',
    'AElig':'Æ',
    'yacute':'ý',
    'Yacute':'Ý',
    'ccedil':'ç',
    'Ccedil':'Ç',
    'yuml':'ÿ',
    'eacute':'é',
    'Eacute':'É',
    'commat':'@',
    'ecirc':'ê',
    'Ecirc':'Ê',
    'ast':'*',
    'egrave':'è',
    'Egrave':'È',
    'circ':'^',
    'tilde':'~',
    'euml':'ë',
    'Euml':'Ë',
    'copy':'©',
    'iacute':'í',
    'Iacute':'Í',
    'dollar':'$',
    'percnt':'%',
    'icirc':'î',
    'Icirc':'Î',
    'num':'#',
    'igrave':'ì',
    'Igrave':'Ì',
    'excl':'!',
    'iexcl':'¡',
    'iuml':'ï',
    'Iuml':'Ï',
    'quest':'?',
    'iquest':'¿',
    'ntilde':'ñ',
    'Ntilde':'Ñ',
    'hyphen':'-',
    'mdash':'—',
    'lowbar':'_',
    'oacute':'ó',
    'Oacute':'Ó',
    'bsol':'\\',
    'ocirc':'ô',
    'Ocirc':'Ô',
    'oelig':'Œ',
    'ograve':'ò',
    'Ograve':'Ò',
    'oslash':'ø',
    'Oslash':'Ø',
    'lsqb':'[',
    'rsqb':']',
    'otilde':'õ',
    'Otilde':'Õ',
    'lcub':'{',
    'rcub':'}',
}

class sgml2xml:

    def __init__(self, src, dst, oprions):
        self.src = src
        self.dst = dst
        self.options = options

    def translate_entity(self, entity):
        if entity in entity_list:
            return entity_list[entity]
        return "&" + entity + ";"

    def read(self, n):
        return self.src.read(n).decode('latin1').encode('utf-8')

    def parse_entity(self):
        char = self.read(1)
        entity = ''
        while True:
            if char == ';':
                break
            entity += char
            char = self.read(1)
        return self.translate_entity(entity);

    def parse_tagname(self, firstchar=None):
        if firstchar == None:
            char = self.read(1)
        tag = ''
        char = firstchar
        # skip initial spaces
        while True:
            if char not in ' \t\n':
                break
            char = self.read(1)

        # get the tag name
        while True:
            if char in ' \t\n>':
                break
            tag += char
            char = self.read(1)
        return tag.lower(), char

    def parse_tree(self, condictional=False):
        fifo = deque()
        res = StringIO()
        while 1:
            char = self.read(1)
            if not char: break
            if condictional and char == ']':
                char = self.read(1)
                if char == ']':
                    char = self.read(1)
                    if char == '>':
                        return res.getvalue()
                    else:
                        res.write(']]')
                else:
                    res.write(']')

            if char == '<':
                char = self.read(1)

                if char == '/':
                    char = self.read(1)
                    tag, char = self.parse_tagname(char)
                    try:
                        stack_tag = fifo.pop()
                        if tag == '':
                            tag = stack_tag
                        else:
                            while stack_tag != tag:
                                res.write('</' + stack_tag + '>')
                                stack_tag = fifo.pop()
                    except IndexError:
                        raise SystemExit('ERROR: trying to pop an empty qeue:\n%s' % res.getvalue()[-100:])
                    res.write('</' + tag + '>')
                    while char != '>':
                        char = self.read(1)

                elif char == '!':
                    char = self.read(2)
                    if char == '--':
                        res.write('<!--')

                        comment_closed = False
                        while comment_closed == False:
                            char = self.read(1)
                            if char == '-':
                                if self.read(2) == '->':
                                    comment_closed = True
                                    res.write('-->')
                            else:
                                res.write(char)

                    elif char == '[C'  and self.read(5) == 'DATA[':
                        res.write('<![CDATA[')

                        cdata_closed = False
                        while cdata_closed == False:
                            char = self.read(1)
                            if char == ']':
                                if self.read(2) == ']>':
                                    cdata_closed = True
                                    res.write(']]>')
                            else:
                                res.write(char)

                    elif char == '[I' and self.read(6) == 'GNORE[':

                        ignore_closed = False
                        while ignore_closed == False:
                            char = self.read(1)
                            if char == ']':
                                if self.read(2) == ']>':
                                    ignore_closed = True

                    elif char == '[%':
                        entity = ''
                        while True:
                            char = self.read(1)
                            if char in ';':
                                self.read(1)
                                break
                            if char in '[':
                                break
                            entity += char;

                        if entity == 'standalone-ignore':
                            if not options['standalone']:
                                res.write(self.parse_tree(True))
                            else:
                                self.parse_tree(True)

                        elif entity == 'standalone-include':
                            if options['standalone']:
                                res.write(self.parse_tree(True))
                            else:
                                self.parse_tree(True)
                        elif entity == 'include-index':
                            if options['index']:
                                res.write(self.parse_tree(True))
                            else:
                                self.parse_tree(True)
                        else:
                            raise SystemExit('ERROR: unknown parameter entity: %%%s' % entity)
                    else:
                        res.write('<!' + char)

                else:
                    tag, char = self.parse_tagname(char)

                    # get params
                    params = ''
                    if char != '>':
                        while True:
                            if char == '&':
                                params += self.parse_entity()
                            else:
                                params = params + char
                            char = self.read(1)
                            if char == '>':
                                break

                    # check if last character of $params is a slash
                    # if it is, remove it from the params
                    if len(params) > 1:
                        if params[-1] == '/':
                            params = params[0:-1]
                    # do the same for tags
                    if tag[-1] == '/':
                        tag = tag[0:-1]


                    # here, char == '>'
                    if tag == 'xref' or tag == 'colspec' or tag == 'sbr' or tag == 'co' or tag == 'spanspec':
                        res.write("<" + tag + params + "/>")
                    else:
                        fifo.append(tag)
                        res.write("<" + tag + params + ">")

            elif char == '&':
                res.write(self.parse_entity())
            else:
                res.write(char)

        return res.getvalue()

    def convert(self):
        res = self.parse_tree()

        self.src.close()
        self.dst.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        self.dst.write(res)
        self.dst.close()

def usage():
    print "usage: " + sys.argv[0] + " [-s] indir outdir"
    print "\t-s: standalone"
    print "\t-i: include index"

def convert_file(src_name, dst_name, options):
    try:
        src_file = open(src_name, 'r')
    except IOError, msg:
        raise SystemExit('ERROR: Error opening input file\n%s' % msg)

    try:
        dst_file = open(dst_name, 'w')
        if dst_name[-4:] != '.xml':
            print >> sys.stderr, 'WARNING: output file extension is not xml'
    except IOError, msg:
        raise SystemExit('ERROR: Error creating output file\n%s' % msg)

    converter = sgml2xml(src_file, dst_file, options)
    converter.convert();

if __name__ == '__main__':
    argn = len(sys.argv)
    if argn not in (3, 4):
        usage()
        sys.exit(1)

    options = {}
    options['standalone'] = False
    options['index'] = False
    while sys.argv[1][1:] in 'si':
        if sys.argv[1] == '-s':
            options['standalone'] = True
        elif sys.argv[1] == '-i':
            options['index'] = True

        del sys.argv[1]

    src = sys.argv[1]
    dst = sys.argv[2]

    if not os.path.isdir(src):
        if os.path.isdir(dst):
            name = os.path.basename(src)
            dst = os.path.join(dst, name)
        convert_file(src, dst, options)
    else:
        if not os.path.isdir(dst):
            try:
                os.makedirs(dst)
            except IOError, msg:
                raise SystemExit('ERROR: Error creating directory\n%s' % msg)
        for root, dirs, files in os.walk(src):
            for file in files:
                fsplit = os.path.splitext(file)
                if fsplit[1] == '.sgml':
                    dst_dir = root.replace(src, dst)
                    if not os.path.isdir(dst_dir):
                        try:
                            os.makedirs(dst_dir)
                        except IOError, msg:
                            raise SystemExit('ERROR: Error creating directory\n%s' % msg)
                    dst_file = os.path.join(dst_dir, fsplit[0] + '.xml')
                    src_file = os.path.join(root, file)
                    print "Generatins %s" % dst_file
                    convert_file(src_file, dst_file, options)
