{-# LANGUAGE CPP #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE TypeFamilies #-}
#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ >= 702
{-# LANGUAGE Trustworthy #-}
#endif
-----------------------------------------------------------------------------
-- |
-- Copyright   :  (C) 2013-2014 Edward Kmett and Dan Doel
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  Rank2Types, TFs
--
----------------------------------------------------------------------------
module Data.Profunctor.Ran
  ( Ran(..)
  , decomposeRan
  , precomposeRan
  ) where

import Control.Category
import Data.Profunctor.Unsafe
import Data.Profunctor.Monad
import Data.Profunctor.Composition
import Prelude hiding (id,(.))

-- | This represents the right Kan lift of a 'Profunctor' @q@ along a 'Profunctor' @p@ in a limited version of the 2-category of Profunctors where the only object is the category Hask, 1-morphisms are profunctors composed and compose with Profunctor composition, and 2-morphisms are just natural transformations.
newtype Ran p q a b = Ran { runRan :: forall x. p x a -> q x b }

instance Category p => ProfunctorComonad (Ran p) where
  proextract (Ran f) = f id
  produplicate (Ran f) = Ran $ \ p -> Ran $ \q -> f (p . q)

instance (Profunctor p, Profunctor q) => Profunctor (Ran p q) where
  dimap ca bd f = Ran (rmap bd . runRan f . rmap ca)
  {-# INLINE dimap #-}
  lmap ca f = Ran (runRan f . rmap ca)
  {-# INLINE lmap #-}
  rmap bd f = Ran (rmap bd . runRan f)
  {-# INLINE rmap #-}
  bd #. f = Ran (\p -> bd #. runRan f p)
  {-# INLINE ( #. ) #-}
  f .# ca = Ran (\p -> runRan f (ca #. p))
  {-# INLINE (.#) #-}

instance Profunctor q => Functor (Ran p q a) where
  fmap bd f = Ran (rmap bd . runRan f)
  {-# INLINE fmap #-}

-- | @'Ran' p p@ forms a 'Monad' in the 'Profunctor' 2-category, which is isomorphic to a Haskell 'Category' instance.
instance p ~ q => Category (Ran p q) where
  id = Ran id
  {-# INLINE id #-}
  Ran f . Ran g = Ran (f . g)
  {-# INLINE (.) #-}

-- | The 2-morphism that defines a right Kan lift.
--
-- Note: When @q@ is left adjoint to @'Ran' q (->)@ then 'decomposeRan' is the 'counit' of the adjunction.
decomposeRan :: Procompose (Ran q p) q a b -> p a b
decomposeRan (Procompose (Ran qp) q) = qp q
{-# INLINE decomposeRan #-}

precomposeRan :: Profunctor q => Procompose q (Ran p (->)) a b -> Ran p q a b
precomposeRan (Procompose p pf) = Ran (\pxa -> runRan pf pxa `lmap` p)
{-# INLINE precomposeRan #-}
