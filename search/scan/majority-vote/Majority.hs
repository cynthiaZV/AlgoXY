-- Majority.hs
-- Copyright (C) 2013 Liu Xinyu (liuxinyu95@gmail.com)
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

module Majority where

import qualified Data.Map.Lazy as Map
import qualified Data.Set as Set
import Test.QuickCheck

-- Boyer-Moore majority vote algorithm based on [1]
-- [1]. Robert Boyer, and Strother Moore. `MJRTY - A Fast Majority Vote Algorithm'. Automated Reasoning: Essays in Honor of Woody Bledsoe, Automated Reasoning Series, Kluwer Academic Publishers, Dordrecht, The Netherlands, 1991, pp. 105-117.

majority xs = verify $ foldr maj (Nothing, 0) xs where
  maj x (Nothing, 0) = (Just x, 1)
  maj x (Just y, v) | x == y = (Just y, v + 1)
                    | v == 0 = (Just x, 1)
                    | otherwise = (Just y, v - 1)
  verify (Nothing, _) = Nothing
  verify (Just m, _)  = if 2 * (length $ filter (==m) xs) > length xs then Just m else Nothing

-- extended: find x that occurs > n/k times in xs, where n = length xs, k > 1 is some integer.
majorities k xs = verify $ foldr maj Map.empty xs where
  maj x m | x `Map.member` m = Map.adjust (1+) x m
          | Map.size m < k = Map.insert x 1 m
          | otherwise = Map.filter (/=0) $ Map.map (-1+) m
  verify m = Map.keys $ Map.filter (> th) $ foldr cnt m' xs where
    m' = Map.map (const 0) m
    cnt x m = if x `Map.member` m then Map.adjust (1+) x m else m
    th = (length xs) `div` k

-- test

naive_maj :: (Eq a, Ord a) => [a] -> Maybe a
naive_maj xs = if v * 2 > length xs then w else Nothing where
  dict = Map.fromListWith (+) (zip (map Just xs) (repeat 1))
  (w, v) = Map.foldrWithKey (\x n (c, m) -> if n > m then (x, n) else (c, m)) (Nothing, 0) dict

naive_majs k xs = Map.keys $ Map.filter (> th) $ Map.fromListWith (+) (zip xs (repeat 1)) where
  th = (length xs) `div` k

--- generate votes of m candidates, and k majorities (> n/k votes)
votesOf k m = map (\x -> ((x `mod` k) * x) `mod` m)

prop_maj :: [Int] -> Bool
prop_maj ns = naive_maj xs == majority xs where
  xs = votesOf 2 5 ns

prop_majs :: [Int] -> Bool
prop_majs ns = bs `Set.isSubsetOf` as where
  xs = votesOf 3 7 ns
  as = Set.fromList $ naive_majs 3 xs
  bs = Set.fromList $ majorities 3 xs
