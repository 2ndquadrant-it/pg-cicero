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

import sys, os
from collections import deque
from cStringIO import StringIO

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

def usage():
    print "usage: " + sys.argv[0] + " [-s] infile outfile \n"
    print " -s: standalone"

def translate_entity(entity):
    if entity in entity_list:
        return entity_list[entity]
    return "&" + entity + ";"

def sgml2xml(src, dst, standalone):

    def read(n):
        return src.read(n).decode('latin1').encode('utf-8')

    def parse_entity():
        char = read(1)
        entity = ''
        while True:
            if char == ';':
                break
            entity += char
            char = read(1)
        return entity;

    def parse_tree(condictional=False):
        fifo = deque()
        res = StringIO()
        while 1:
            char = read(1)
            if not char: break
            if condictional and char == ']':
                char = read(2)
                if char == ']>':
                    return res.getvalue()
                else:
                    char = ']'
                    src.seek(-2, os.SEEK_CUR)

            if char == '<':
                char = read(1)

                if char == '/':
                    try:
                        res.write('</' + fifo.pop() + '>')
                    except IndexError:
                        raise SystemExit('ERROR: trying to pop an empty qeue')

                    while char != '>':
                        char = read(1)

                elif char == '!':
                    char = read(2)
                    if char == '--':
                        res.write('<!--')

                        comment_closed = False
                        while comment_closed == False:
                            char = read(1)
                            if char == '-':
                                if read(2) == '->':
                                    comment_closed = True
                                    res.write('-->')
                            else:
                                res.write(char)

                    elif char == '[C'  and read(5) == 'DATA[':
                        res.write('<![CDATA[')

                        cdata_closed = False
                        while cdata_closed == False:
                            char = read(1)
                            if char == ']':
                                if read(2) == ']>':
                                    cdata_closed = True
                                    res.write(']]>')
                            else:
                                res.write(char)

                    elif char == '[I' and read(6) == 'GNORE[':

                        ignore_closed = False
                        while ignore_closed == False:
                            char = read(1)
                            if char == ']':
                                if read(2) == ']>':
                                    ignore_closed = True

                    elif char == '[%' and read(11) == 'standalone-':

                        aux = read(2)
                        if aux == 'ig':
                            char = read(6)
                            if char[-1] != '[':
                                src.seek(-1, os.SEEK_CUR)
                            if not standalone:
                                res.write(parse_tree(True))
                            else:
                                parse_tree(True)

                        elif aux == 'in':
                            char = read(7)
                            if char[-1] != '[':
                                src.seek(-1, os.SEEK_CUR)
                            if standalone:
                                res.write(parse_tree(True))
                            else:
                                parse_tree(True)
                        else:
                            raise SystemExit('ERROR: unknown "<![%standalone-" directive')
                    else:
                        res.write('<!' + char)

                else:
                    tag = char
                    char = read(1)
                    params = ''
                    # get the tag name
                    while True:
                        tag += char
                        char = read(1)
                        if char == ' ' or char == '\t' or  char == '\n'  or char == '>':
                            break

                    # get params
                    if char != '>':
                        while True:
                            if char == '&':
                                entity = parse_entity()
                                params += translate_entity(entity)
                            else:
                                params = params + char
                            char = read(1)
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
                entity = parse_entity()
                res.write(translate_entity(entity))
            else:
                res.write(char)

        return res.getvalue()

    res = parse_tree()

    src.close()
    dst.write('<?xml version="1.0" encoding="UTF-8"?>\n')
    dst.write(res)
    dst.close()

if __name__ == '__main__':
    argn = len(sys.argv)
    if argn not in (3, 4):
        usage()
        sys.exit(1)

    if sys.argv[1] == '-s':
        standalone = True
        del sys.argv[1]
    else:
        standalone = False

    src_name = sys.argv[1]
    dst_name = sys.argv[2]
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

    sgml2xml(src_file, dst_file, standalone)

