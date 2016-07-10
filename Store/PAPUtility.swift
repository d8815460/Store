import Foundation
import CoreGraphics
import UIImageAFAdditions
import ParseFacebookUtilsV4

class PAPUtility {

    // MARK:- PAPUtility

    // MARK Like Photos

    class func likePhotoInBackground(photo: PFObject, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        let queryExistingLikes = PFQuery(className: kPAPActivityClassKey)
        queryExistingLikes.whereKey(kPAPActivityPhotoKey, equalTo: photo)
        queryExistingLikes.whereKey(kPAPActivityTypeKey, equalTo: kPAPActivityTypeLike)
        queryExistingLikes.whereKey(kPAPActivityFromUserKey, equalTo: PFUser.current()!)
        queryExistingLikes.cachePolicy = PFCachePolicy.networkOnly
        queryExistingLikes.findObjectsInBackground { (activities, error) in
            if error == nil {
                for activity in activities as [PFObject]! {
// FIXME: To be removed! this is synchronous!                    activity.delete()
                    activity.deleteInBackground()
                }
            }

            // proceed to creating new like
            let likeActivity = PFObject(className: kPAPActivityClassKey)
            likeActivity.setObject(kPAPActivityTypeLike, forKey: kPAPActivityTypeKey)
            likeActivity.setObject(PFUser.current()!, forKey: kPAPActivityFromUserKey)
            likeActivity.setObject(photo.object(forKey: kPAPPhotoUserKey)!, forKey: kPAPActivityToUserKey)
            likeActivity.setObject(photo, forKey: kPAPActivityPhotoKey)

            let likeACL = PFACL(user: PFUser.current()!)
            likeACL.getPublicReadAccess = true
            likeACL.setWriteAccess(true, for: photo.object(forKey: kPAPPhotoUserKey) as! PFUser)
            likeActivity.acl = likeACL

            likeActivity.saveInBackground { (succeeded, error) in
                if completionBlock != nil {
                    completionBlock!(succeeded: succeeded.boolValue, error: error)
                }

                // refresh cache
                let query = PAPUtility.queryForActivitiesOnPhoto(photo: photo, cachePolicy: PFCachePolicy.networkOnly)
                query.findObjectsInBackground { (objects, error) in
                    if error == nil {
                        var likers = [PFUser]()
                        var commenters = [PFUser]()

                        var isLikedByCurrentUser = false

                        for activity in objects as [PFObject]! {
                            if (activity.object(forKey: kPAPActivityTypeKey) as! String) == kPAPActivityTypeLike && activity.object(forKey: kPAPActivityFromUserKey) != nil {
                                likers.append(activity.object(forKey: kPAPActivityFromUserKey) as! PFUser)
                            } else if (activity.object(forKey: kPAPActivityTypeKey) as! String) == kPAPActivityTypeComment && activity.object(forKey: kPAPActivityFromUserKey) != nil {
                                commenters.append(activity.object(forKey: kPAPActivityFromUserKey) as! PFUser)
                            }

                            if (activity.object(forKey: kPAPActivityFromUserKey) as? PFUser)?.objectId == PFUser.current()!.objectId {
                                if (activity.object(forKey: kPAPActivityTypeKey) as! String) == kPAPActivityTypeLike {
                                    isLikedByCurrentUser = true
                                }
                            }
                        }

                        PAPCache.sharedCache.setAttributesForPhoto(photo: photo, likers: likers, commenters: commenters, likedByCurrentUser: isLikedByCurrentUser)
                    }
                    NotificationCenter.default().post(name: NSNotification.Name(rawValue: PAPUtilityUserLikedUnlikedPhotoCallbackFinishedNotification), object: photo, userInfo: [PAPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotificationUserInfoLikedKey: succeeded.boolValue])
                }

            }
        }
    }

    class func unlikePhotoInBackground(photo: PFObject, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        let queryExistingLikes = PFQuery(className: kPAPActivityClassKey)
        queryExistingLikes.whereKey(kPAPActivityPhotoKey, equalTo: photo)
        queryExistingLikes.whereKey(kPAPActivityTypeKey, equalTo: kPAPActivityTypeLike)
        queryExistingLikes.whereKey(kPAPActivityFromUserKey, equalTo: PFUser.current()!)
        queryExistingLikes.cachePolicy = PFCachePolicy.networkOnly
        queryExistingLikes.findObjectsInBackground { (activities, error) in
            if error == nil {
                for activity in activities as [PFObject]! {
// FIXME: To be removed! this is synchronous!                    activity.delete()
                    activity.deleteInBackground()
                }

                if completionBlock != nil {
                    completionBlock!(succeeded: true, error: nil)
                }

                // refresh cache
                let query = PAPUtility.queryForActivitiesOnPhoto(photo: photo, cachePolicy: PFCachePolicy.networkOnly)
                query.findObjectsInBackground { (objects, error) in
                    if error == nil {

                        var likers = [PFUser]()
                        var commenters = [PFUser]()

                        var isLikedByCurrentUser = false

                        for activity in objects as [PFObject]! {
                            if (activity.object(forKey: kPAPActivityTypeKey) as! String) == kPAPActivityTypeLike {
                                likers.append(activity.object(forKey: kPAPActivityFromUserKey) as! PFUser)
                            } else if (activity.object(forKey: kPAPActivityTypeKey) as! String) == kPAPActivityTypeComment {
                                commenters.append(activity.object(forKey: kPAPActivityFromUserKey) as! PFUser)
                            }

                            if (activity.object(forKey: kPAPActivityFromUserKey) as! PFUser).objectId == PFUser.current()!.objectId {
                                if (activity.object(forKey: kPAPActivityTypeKey) as! String) == kPAPActivityTypeLike {
                                    isLikedByCurrentUser = true
                                }
                            }
                        }

                        PAPCache.sharedCache.setAttributesForPhoto(photo: photo, likers: likers, commenters: commenters, likedByCurrentUser: isLikedByCurrentUser)
                    }
                    NotificationCenter.default().post(name: NSNotification.Name(rawValue: PAPUtilityUserLikedUnlikedPhotoCallbackFinishedNotification), object: photo, userInfo: [PAPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotificationUserInfoLikedKey: false])
                }

            } else {
                if completionBlock != nil {
                    completionBlock!(succeeded: false, error: error)
                }
            }
        }
    }

    // MARK Facebook

    class func processFacebookProfilePictureData(newProfilePictureData: NSData) {
        print("Processing profile picture of size: \(newProfilePictureData.length)")
        if newProfilePictureData.length == 0 {
            return
        }

        let image = UIImage(data: newProfilePictureData as Data)

        let mediumImage: UIImage = image!.thumbnailImage(280, transparentBorder: 0, cornerRadius: 0, interpolationQuality: CGInterpolationQuality.high)
        let smallRoundedImage: UIImage = image!.thumbnailImage(64, transparentBorder: 0, cornerRadius: 0, interpolationQuality: CGInterpolationQuality.low)

        let mediumImageData: NSData = UIImageJPEGRepresentation(mediumImage, 0.5)! // using JPEG for larger pictures
        let smallRoundedImageData: NSData = UIImagePNGRepresentation(smallRoundedImage)!

        if mediumImageData.length > 0 {
            let fileMediumImage: PFFile = PFFile(data: mediumImageData as Data)!
            fileMediumImage.saveInBackground { (succeeded, error) in
                if error == nil {
                    PFUser.current()!.setObject(fileMediumImage, forKey: kPAPUserProfilePicMediumKey)
                    PFUser.current()!.saveInBackground()
                }
            }
        }

        if smallRoundedImageData.length > 0 {
            let fileSmallRoundedImage: PFFile = PFFile(data: smallRoundedImageData as Data)!
            fileSmallRoundedImage.saveInBackground { (succeeded, error) in
                if error == nil {
                    PFUser.current()!.setObject(fileSmallRoundedImage, forKey: kPAPUserProfilePicSmallKey)
                    PFUser.current()!.saveInBackground()
                }
            }
        }
        print("Processed profile picture")
    }

    class func userHasValidFacebookData(user: PFUser) -> Bool {
        // Check that PFUser has valid fbid that matches current FBSessions userId
        let facebookId = user.object(forKey: kPAPUserFacebookIDKey) as? String
        
        return (facebookId != nil && facebookId?.characters.count > 0 && facebookId == FBSDKAccessToken.current().userID)
    }

    class func userHasProfilePictures(user: PFUser) -> Bool {
        let profilePictureMedium: PFFile? = user.object(forKey: kPAPUserProfilePicMediumKey) as? PFFile
        let profilePictureSmall: PFFile? = user.object(forKey: kPAPUserProfilePicSmallKey) as? PFFile

        return profilePictureMedium != nil && profilePictureSmall != nil
    }

    class func defaultProfilePicture() -> UIImage? {
        return UIImage(named: "AvatarPlaceholderBig.png")
    }

    // MARK Display Name

    class func firstNameForDisplayName(displayName: String?) -> String {
        if (displayName == nil || displayName?.characters.count == 0) {
            return "Someone"
        }
        let displayNameComponents: [String] = (displayName?.components(separatedBy: " "))!
        var firstName = displayNameComponents[0]
        if firstName.characters.count > 100 {
            // truncate to 100 so that it fits in a Push payload
            
//            firstName = firstName.substring(with: Range(0..<100))
//            firstName = firstName.subString(0, length: 100)
        }
        return firstName
    }

    // MARK User Following

    class func followUserInBackground(user: PFUser, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        if user.objectId == PFUser.current()!.objectId {
            return
        }

        let followActivity = PFObject(className: kPAPActivityClassKey)
        followActivity.setObject(PFUser.current()!, forKey: kPAPActivityFromUserKey)
        followActivity.setObject(user, forKey: kPAPActivityToUserKey)
        followActivity.setObject(kPAPActivityTypeFollow, forKey: kPAPActivityTypeKey)

        let followACL = PFACL(user: PFUser.current()!)
        followACL.getPublicReadAccess = true
        followActivity.acl = followACL

        followActivity.saveInBackground { (succeeded, error) in
            if completionBlock != nil {
                completionBlock!(succeeded: succeeded.boolValue, error: error)
            }
        }
        PAPCache.sharedCache.setFollowStatus(following: true, user: user)
    }

    class func followUserEventually(user: PFUser, block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        if user.objectId == PFUser.current()!.objectId {
            return
        }

        let followActivity = PFObject(className: kPAPActivityClassKey)
        followActivity.setObject(PFUser.current()!, forKey: kPAPActivityFromUserKey)
        followActivity.setObject(user, forKey: kPAPActivityToUserKey)
        followActivity.setObject(kPAPActivityTypeFollow, forKey: kPAPActivityTypeKey)

        let followACL = PFACL(user: PFUser.current()!)
        followACL.getPublicReadAccess = true
        followActivity.acl = followACL

        followActivity.saveEventually(completionBlock)
        PAPCache.sharedCache.setFollowStatus(following: true, user: user)
    }

    class func followUsersEventually(users: [PFUser], block completionBlock: ((succeeded: Bool, error: NSError?) -> Void)?) {
        for user: PFUser in users {
            PAPUtility.followUserEventually(user: user, block: completionBlock)
            PAPCache.sharedCache.setFollowStatus(following: true, user: user)
        }
    }

    class func unfollowUserEventually(user: PFUser) {
        let query = PFQuery(className: kPAPActivityClassKey)
        query.whereKey(kPAPActivityFromUserKey, equalTo: PFUser.current()!)
        query.whereKey(kPAPActivityToUserKey, equalTo: user)
        query.whereKey(kPAPActivityTypeKey, equalTo: kPAPActivityTypeFollow)
        query.findObjectsInBackground { (followActivities, error) in
            // While normally there should only be one follow activity returned, we can't guarantee that.
            if error == nil {
                for followActivity: PFObject in followActivities as [PFObject]! {
                    followActivity.deleteEventually()
                }
            }
        }
        PAPCache.sharedCache.setFollowStatus(following: false, user: user)
    }

    class func unfollowUsersEventually(users: [PFUser]) {
        let query = PFQuery(className: kPAPActivityClassKey)
        query.whereKey(kPAPActivityFromUserKey, equalTo: PFUser.current()!)
        query.whereKey(kPAPActivityToUserKey, containedIn: users)
        query.whereKey(kPAPActivityTypeKey, equalTo: kPAPActivityTypeFollow)
        query.findObjectsInBackground { (activities, error) in
            for activity in activities as [PFObject]! {
                activity.deleteEventually()
            }
        }
        for user in users {
            PAPCache.sharedCache.setFollowStatus(following: false, user: user)
        }
    }

    // MARK Activities

    class func queryForActivitiesOnPhoto(photo: PFObject, cachePolicy: PFCachePolicy) -> PFQuery<PFObject> {
        let queryLikes: PFQuery = PFQuery(className: kPAPActivityClassKey)
        queryLikes.whereKey(kPAPActivityPhotoKey, equalTo: photo)
        queryLikes.whereKey(kPAPActivityTypeKey, equalTo: kPAPActivityTypeLike)

        let queryComments = PFQuery(className: kPAPActivityClassKey)
        queryComments.whereKey(kPAPActivityPhotoKey, equalTo: photo)
        queryComments.whereKey(kPAPActivityTypeKey, equalTo: kPAPActivityTypeComment)

        let query = PFQuery.orQuery(withSubqueries: [queryLikes,queryComments])
        query.cachePolicy = cachePolicy
        query.includeKey(kPAPActivityFromUserKey)
        query.includeKey(kPAPActivityPhotoKey)

        return query
    }

    // MARK:- Shadow Rendering

    class func drawSideAndBottomDropShadowForRect(rect: CGRect, inContext context: CGContext) {
        // Push the context
        context.saveGState()

        // Set the clipping path to remove the rect drawn by drawing the shadow
        let boundingRect: CGRect = context.boundingBoxOfClipPath
        context.addRect(boundingRect)
        context.addRect(rect)
        context.eoClip()
        // Also clip the top and bottom
        context.clipTo(CGRect(x: rect.origin.x - 10.0, y: rect.origin.y, width: rect.size.width + 20.0, height: rect.size.height + 10.0))

        // Draw shadow
        UIColor.black().setFill()
        context.setShadow(offset: CGSize(width: 0.0, height: 0.0), blur: 7.0)
        context.fill(CGRect(x: rect.origin.x, y: rect.origin.y - 5.0, width: rect.size.width, height: rect.size.height + 5.0))
        // Save context
        context.restoreGState()
    }

    class func drawSideAndTopDropShadowForRect(rect: CGRect, inContext context: CGContext) {
        // Push the context
        context.saveGState()

        // Set the clipping path to remove the rect drawn by drawing the shadow
        let boundingRect: CGRect = context.boundingBoxOfClipPath
        context.addRect(boundingRect)
        context.addRect(rect)
        context.eoClip()
        // Also clip the top and bottom
        context.clipTo(CGRect(x: rect.origin.x - 10.0, y: rect.origin.y - 10.0, width: rect.size.width + 20.0, height: rect.size.height + 10.0))

        // Draw shadow
        UIColor.black().setFill()
        context.setShadow(offset: CGSize(width: 0.0, height: 0.0), blur: 7.0)
        context.fill(CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height + 10.0))
        // Save context
        context.restoreGState()
    }

    class func drawSideDropShadowForRect(rect: CGRect, inContext context: CGContext) {
        // Push the context
        context.saveGState()

        // Set the clipping path to remove the rect drawn by drawing the shadow
        let boundingRect: CGRect = context.boundingBoxOfClipPath
        context.addRect(boundingRect)
        context.addRect(rect)
        context.eoClip()
        // Also clip the top and bottom
        context.clipTo(CGRect(x: rect.origin.x - 10.0, y: rect.origin.y, width: rect.size.width + 20.0, height: rect.size.height))

        // Draw shadow
        UIColor.black().setFill()
        context.setShadow(offset: CGSize(width: 0.0, height: 0.0), blur: 7.0)
        context.fill(CGRect(x: rect.origin.x, y: rect.origin.y - 5.0, width: rect.size.width, height: rect.size.height + 10.0))
        // Save context
        context.restoreGState()
    }
}
