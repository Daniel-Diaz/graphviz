{- |
   Module      : Data.GraphViz.Commands.IO
   Description : IO-related functions for graphviz.
   Copyright   : (c) Ivan Lazar Miljenovic
   License     : 3-Clause BSD-style
   Maintainer  : Ivan.Miljenovic@gmail.com

   Various utility functions to help with custom I\/O of Dot code.
-}
module Data.GraphViz.Commands.IO
       ( -- * Encoding
         -- $encoding
         -- * Operations on files
         writeDotFile
       , readDotFile
         -- * Operations on handles
       , hPutDot
       , hPutCompactDot
       , hGetDot
         -- * Special cases for standard input and output
       , putDot
       , readDot
       ) where

import Data.GraphViz.Types(DotRepr, printDotGraph, parseDotGraph)
import Data.GraphViz.Printing(toDot)
import Text.PrettyPrint.Leijen.Text(displayT, renderCompact)

import qualified Data.Text.Lazy.Encoding as T
import Data.Text.Lazy(Text)
import qualified Data.ByteString.Lazy as B
import Data.ByteString.Lazy(ByteString)
import Control.Monad(liftM)
import System.IO(Handle, IOMode(ReadMode,WriteMode),withFile, stdout, stdin)

-- -----------------------------------------------------------------------------

-- | Correctly render Graphviz output in a more machine-oriented form
--   (i.e. more compact than the output of 'renderDot').
renderCompactDot :: (DotRepr dg n) => dg n -> Text
renderCompactDot = displayT . renderCompact . toDot

-- -----------------------------------------------------------------------------
-- Encoding

{- $encoding
  By default, Dot code should be in UTF-8.  However, by usage of the
  /charset/ attribute, users are able to specify that the ISO-8859-1
  (aka Latin1) encoding should be used instead:
  <http://www.graphviz.org/doc/info/attrs.html#d:charset>

  To simplify matters, graphviz does /not/ work with ISO-8859-1.  If
  you wish to deal with existing Dot code that uses this encoding, you
  will need to manually read that file in to a 'Text' value.
http://github.com/jgm/illuminate-
  If a file uses a non-UTF-8 encoding, then a @UnicodeException@ error
  (see "Data.Text.Encoding.Error") will be thrown.
-}

encodeDot :: (DotRepr dg n) => dg n -> ByteString
encodeDot = T.encodeUtf8 . printDotGraph

-- | Encodes the machine-friendly representation generated by
--   'renderCompactDot' using the appropriate encoding.
encodeCompactDot :: (DotRepr dg n) => dg n -> ByteString
encodeCompactDot = T.encodeUtf8 . renderCompactDot

decodeDot :: (DotRepr dg n) => ByteString -> dg n
decodeDot = parseDotGraph . T.decodeUtf8

-- -----------------------------------------------------------------------------
-- Output

hPutDot   :: (DotRepr dg n) => Handle -> dg n -> IO ()
hPutDot h = B.hPutStr h . encodeDot

hPutCompactDot :: (DotRepr dg n) => Handle -> dg n -> IO ()
hPutCompactDot h = B.hPutStr h . encodeCompactDot

hGetDot :: (DotRepr dg n) => Handle -> IO (dg n)
hGetDot = liftM decodeDot . B.hGetContents

writeDotFile   :: (DotRepr dg n) => FilePath -> dg n -> IO ()
writeDotFile f = withFile f WriteMode . flip hPutDot

readDotFile   :: (DotRepr dg n) => FilePath -> IO (dg n)
readDotFile f = withFile f ReadMode hGetDot

putDot :: (DotRepr dg n) => dg n -> IO ()
putDot = hPutDot stdout

readDot :: (DotRepr dg n) => IO (dg n)
readDot = hGetDot stdin
