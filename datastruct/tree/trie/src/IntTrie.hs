{-
    IntTrie.hs, Integer base Trie
    Copyright (C) 2010, Liu Xinyu (liuxinyu95@gmail.com)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
-}

-- Int (as key) Radix tree
-- Referred from Haskell packages Data.IntMap
-- Other reference includes:
--  [1] CLRS, Problems 12-2: Radix trees
--  [2] Chris Okasaki and Andy Gill,  \"/Fast Mergeable Integer Maps/\",
--	Workshop on ML, September 1998, pages 77-86,
--	<http://www.cse.ogi.edu/~andy/pub/finite.htm>

-- A very simple int (binary) trie as CLRS 12-2 (Little-Edian)
module IntTrie where

import Test.QuickCheck
import Data.Maybe (isNothing)
import Prelude hiding (lookup)
import Data.List (sort)

data IntTrie a = Empty
               | Branch (IntTrie a) (Maybe a) (IntTrie a) -- left, value, right
               deriving Show

type Key = Int

left (Branch l _ _) = l
left Empty = Empty

right (Branch _ _ r) = r
right Empty = Empty

value (Branch _ v _) = v
value Empty = Nothing

-- override the value if key already exits
-- insert :: Key -> a -> IntTrie a -> IntTrie a
insert k x Empty = insert k x (Branch Empty Nothing Empty)
insert 0 x (Branch l v r) = Branch l (Just x) r
insert k x (Branch l v r) | even k    = Branch (insert (k `div` 2) x l) v r
                          | otherwise = Branch l v (insert (k `div` 2) x r)

lookup _ Empty = Nothing
lookup 0 (Branch _ v _) = v
lookup k (Branch l _ r) | even k    = lookup (k `div` 2) l
                        | otherwise = lookup (k `div` 2) r

fromList = foldr (uncurry insert) Empty

-- fold in pre-order
-- k = (... a2 a1 a0)_2 ==> k' = am * n + k, where n = 2^m, am = 0 or 1.
foldpre f z = go 0 1 z where
  go _ _ z Empty = z
  go k n z (Branch l m r) = f k m (go k (2 * n) (go (n + k) (2 * n) z r) l)

toList = foldpre f [] where
  f _ Nothing xs = xs
  f k (Just v) xs = (k, v) : xs

keys = fst . unzip . toList

values = snd . unzip . toList


-- Verification

data Sample = S [(Key, Int)] [Int] deriving Show

instance Arbitrary Sample where
  arbitrary = do
    n <- choose (2, 100)
    xs <- shuffle [0..100]
    let (ks, ks') = splitAt n xs
    return $ S (zip ks [1..]) ks'

prop_build :: Sample -> Bool
prop_build (S kvs ks') = let t = fromList kvs in
  (all (\(k, v) -> Just v == lookup k t) kvs ) &&
  (all (isNothing . (flip lookup) t) ks')

prop_traverse :: Sample -> Bool
prop_traverse (S kvs _) = (sort kvs) == (sort $ toList $ fromList kvs)

prop_preorder :: Sample -> Bool
prop_preorder (S kvs _) = sorted $ map bitsLE $ keys $ fromList kvs where
  sorted [] = True
  sorted xs = and $ zipWith (<=) xs (tail xs)

bitsLE 0 = []
bitsLE n = (n `mod` 2) : bitsLE (n `div` 2)

testAll = do
  quickCheck prop_build
  quickCheck prop_traverse

-- example: t = fromList [(1, 'a'), (4, 'b'), (5, 'c'), (9, 'd')]
