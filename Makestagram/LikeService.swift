//
//  LikeService.swift
//  Makestagram
//
//  Created by Fernando on 6/28/17.
//  Copyright © 2017 Specialist. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct LikeService {
    
    static func create(for post: Post, success: @escaping (Bool) -> Void) {
        
        guard let key = post.key else {
            return success(false)
        }
        
        let currentUID = User.current.uid
        
        let likesRef = Database.database().reference().child(Constants.Post.postLikes).child(key).child(currentUID)
        
        likesRef.setValue(true) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return success(false)
            }
            
            let likeCountRef = Database.database().reference().child(Constants.Post.posts).child(post.poster.uid).child(key).child(Constants.Post.likeCount)
            
            likeCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                
                mutableData.value = currentCount + 1
                
                return TransactionResult.success(withValue: mutableData)
                
            }, andCompletionBlock: { (error, _, _) in
                if let err = error {
                    assertionFailure(err.localizedDescription)
                    success(false)
                } else {
                    success(true)
                }
                
            })
            
            
            return success(true)
        }
        
    }
    
    static func delete(for post: Post, success: @escaping (Bool) -> Void) {
        
        guard let key = post.key else {
            return success(false)
        }
        
        let currentUID = User.current.uid
        
        let likesRef = Database.database().reference().child(Constants.Post.postLikes).child(key).child(currentUID)
        
        likesRef.setValue(nil) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return success(false)
            }
            
            let likeCountRef = Database.database().reference().child(Constants.Post.posts).child(post.poster.uid).child(key).child(Constants.Post.likeCount)
            
            likeCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                
                mutableData.value = currentCount - 1
                
                return TransactionResult.success(withValue: mutableData)
            }, andCompletionBlock: { (error, _, _) in
                if let err = error {
                    assertionFailure(err.localizedDescription)
                    success(false)
                } else {
                    success(true)
                }
            
            })
            
            return success(true)
        }
        
    }
    
    static func isPostLiked(_ post: Post, byCurrentUserWithCompletion completion: @escaping (Bool) -> Void) {
        guard let postKey = post.key else {
            assertionFailure("Error: post must have key.")
            return completion(false)
        }
        
        let likesRef = Database.database().reference().child(Constants.Post.postLikes).child(postKey)
        
        likesRef.queryEqual(toValue: nil, childKey: User.current.uid).observeSingleEvent(of: .value, with:{ (snapshot) in
            if let _ = snapshot.value as? [ String: Bool]{
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    static func setIsLiked(_ isLiked: Bool, for post: Post, success: @escaping (Bool) -> Void) {
        if isLiked {
            create(for: post, success: success)
        } else {
            delete(for: post, success: success)
        }
    }
}
